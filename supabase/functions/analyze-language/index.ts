import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const allowedOrigins = new Set([
  "https://jiao1321-del.github.io",
  "http://localhost:3000",
  "http://localhost:5000",
  "http://localhost:8080",
]);

function corsHeaders(origin: string | null) {
  const allowOrigin =
    origin && allowedOrigins.has(origin)
      ? origin
      : "https://jiao1321-del.github.io";

  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Headers": "authorization, apikey, content-type",
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    "Vary": "Origin",
  };
}

function jsonResponse(
  body: unknown,
  status: number,
  origin: string | null,
) {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      ...corsHeaders(origin),
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
    },
  });
}

function extractOutputText(data: any): string | null {
  if (typeof data?.output_text === "string" && data.output_text.length > 0) {
    return data.output_text;
  }

  const output = Array.isArray(data?.output) ? data.output : [];
  for (const item of output) {
    const content = Array.isArray(item?.content) ? item.content : [];
    for (const part of content) {
      if (part?.type === "output_text" && typeof part?.text === "string") {
        return part.text;
      }
    }
  }

  return null;
}

Deno.serve(async (req: Request) => {
  const origin = req.headers.get("origin");

  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: corsHeaders(origin),
    });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405, origin);
  }

  try {
    const body = await req.json();
    const text =
      typeof body?.text === "string" ? body.text.trim() : "";

    if (!text) {
      return jsonResponse({ error: "請先輸入要分析的句子。" }, 400, origin);
    }

    if (text.length > 2000) {
      return jsonResponse(
        { error: "內容太長，請控制在 2000 個字元以內。" },
        400,
        origin,
      );
    }

    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (!apiKey) {
      return jsonResponse(
        {
          error: "AI_BACKEND_NOT_CONFIGURED",
          message: "Supabase 尚未設定 OPENAI_API_KEY。",
        },
        503,
        origin,
      );
    }

    const schema = {
      type: "object",
      additionalProperties: false,
      properties: {
        detectedLanguage: {
          type: "string",
          enum: [
            "Chinese",
            "English",
            "Tagalog",
            "Taglish",
            "Mixed",
            "Other",
          ],
        },
        chinese: {
          type: "string",
          description: "自然、符合台灣使用習慣的繁體中文。",
        },
        english: {
          type: "string",
          description: "自然、日常且文法正確的英文。",
        },
        tagalog: {
          type: "string",
          description:
            "自然的 Tagalog；若實際菲律賓日常更常用 Taglish，可自然使用 Taglish。",
        },
        learningPoints: {
          type: "array",
          minItems: 2,
          maxItems: 5,
          items: {
            type: "object",
            additionalProperties: false,
            properties: {
              title: {
                type: "string",
                description: "保留值得學習的原語言詞彙、片語或文法名稱；必要時可附簡短繁中提示。",
              },
              explanation: {
                type: "string",
                description: "必須使用自然、清楚的台灣繁體中文解釋。原語言只可出現在例詞或例句中，不可整段用英文、Tagalog 或 Taglish 說明。",
              },
            },
            required: ["title", "explanation"],
          },
        },
        tone: {
          type: "string",
          description: "必須使用台灣繁體中文，簡短說明原句語氣、禮貌度、文化差異與適合使用的情境。",
        },
      },
      required: [
        "detectedLanguage",
        "chinese",
        "english",
        "tagalog",
        "learningPoints",
        "tone",
      ],
    };

    const prompt = [
      "You are LinguaMate, a multilingual language-learning coach for a Traditional Chinese speaking learner.",
      "Analyze the user's sentence and return useful learning material in Traditional Chinese, English, and Tagalog/Taglish.",
      "Do not translate word-for-word when that would sound unnatural.",
      "For English, prefer natural everyday phrasing.",
      "For Tagalog, prefer natural Filipino usage; Taglish is allowed when it is more idiomatic in daily conversation.",
      "The learner's interface language and explanation language is Traditional Chinese (Taiwan).",
      "CRITICAL: learningPoints[].explanation and tone MUST be written in Traditional Chinese used in Taiwan, even when the source sentence is Tagalog, Taglish, English, or mixed.",
      "learningPoints[].title may preserve the original vocabulary or phrase being taught, such as \"po / kayo\" or \"kuya pogi\", but the explanation underneath must be Traditional Chinese.",
      "Do not write a full explanation paragraph in Tagalog, Taglish, or English. Those languages may only appear as the term being discussed or inside short example sentences.",
      "Learning points should explain vocabulary, grammar, tone, politeness, or culturally useful usage from the perspective of a Traditional Chinese-speaking learner.",
      "Keep each field concise and practical.",
      "",
      "User sentence:",
      text,
    ].join("\n");

    const openAIResponse = await fetch("https://api.openai.com/v1/responses", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${apiKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: "gpt-5.6-luna",
        reasoning: { effort: "low" },
        store: false,
        max_output_tokens: 1800,
        input: prompt,
        text: {
          format: {
            type: "json_schema",
            name: "linguamate_analysis",
            strict: true,
            schema,
          },
        },
      }),
    });

    const responseData = await openAIResponse.json();

    if (!openAIResponse.ok) {
      console.error("OpenAI API error", {
        status: openAIResponse.status,
        error: responseData?.error?.message ?? "unknown",
      });

      return jsonResponse(
        {
          error: "AI_REQUEST_FAILED",
          message: "AI 分析暫時失敗，請稍後再試。",
        },
        502,
        origin,
      );
    }

    const outputText = extractOutputText(responseData);
    if (!outputText) {
      return jsonResponse(
        {
          error: "AI_EMPTY_RESPONSE",
          message: "AI 沒有回傳可用內容，請再試一次。",
        },
        502,
        origin,
      );
    }

    let analysis: unknown;
    try {
      analysis = JSON.parse(outputText);
    } catch {
      return jsonResponse(
        {
          error: "AI_INVALID_RESPONSE",
          message: "AI 回傳格式異常，請再試一次。",
        },
        502,
        origin,
      );
    }

    return jsonResponse({ analysis }, 200, origin);
  } catch (error) {
    console.error("LinguaMate analyze error", error);
    return jsonResponse(
      {
        error: "INTERNAL_ERROR",
        message: "分析時發生錯誤，請稍後再試。",
      },
      500,
      origin,
    );
  }
});
