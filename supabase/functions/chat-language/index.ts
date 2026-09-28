import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const allowedOrigins = new Set([
  "https://jiao1321-del.github.io",
  "http://localhost:3000",
  "http://localhost:5000",
  "http://localhost:8080",
]);

const allowedTargets = new Set(["English", "Tagalog", "Taglish"]);
const allowedScenarios = new Set(["自由對話", "日常生活", "工作職場", "旅行"]);

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
    return new Response("ok", { headers: corsHeaders(origin) });
  }

  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405, origin);
  }

  try {
    const body = await req.json();
    const message =
      typeof body?.message === "string" ? body.message.trim() : "";
    const targetLanguage =
      typeof body?.targetLanguage === "string"
        ? body.targetLanguage.trim()
        : "English";
    const rawScenario =
      typeof body?.scenario === "string" ? body.scenario.trim() : "自由對話";
    const memoryMarker = "\n\nLearner memory:";
    const markerIndex = rawScenario.indexOf(memoryMarker);
    const scenario =
      markerIndex >= 0 ? rawScenario.slice(0, markerIndex).trim() : rawScenario;
    const legacyLearnerMemory =
      markerIndex >= 0
        ? rawScenario.slice(markerIndex + memoryMarker.length).trim()
        : "";
    const learnerMemory =
      typeof body?.learnerMemory === "string"
        ? body.learnerMemory.trim().slice(0, 2000)
        : legacyLearnerMemory.slice(0, 2000);

    if (!message) {
      return jsonResponse(
        { error: "請先輸入想和 AI 練習的內容。" },
        400,
        origin,
      );
    }

    if (message.length > 1000) {
      return jsonResponse(
        { error: "訊息太長，請控制在 1000 個字元以內。" },
        400,
        origin,
      );
    }

    if (!allowedTargets.has(targetLanguage)) {
      return jsonResponse(
        { error: "不支援的學習語言。" },
        400,
        origin,
      );
    }

    const isRoleplayMission = scenario.startsWith("任務｜");
    if (!allowedScenarios.has(scenario) && !isRoleplayMission) {
      return jsonResponse(
        { error: "不支援的對話情境。" },
        400,
        origin,
      );
    }

    if (scenario.length > 500) {
      return jsonResponse(
        { error: "情境內容過長。" },
        400,
        origin,
      );
    }

    const rawHistory = Array.isArray(body?.history) ? body.history : [];
    const history = rawHistory
      .slice(-8)
      .map((item: any) => ({
        role: item?.role === "assistant" ? "assistant" : "user",
        content:
          typeof item?.content === "string"
            ? item.content.trim().slice(0, 1000)
            : "",
      }))
      .filter((item: { content: string }) => item.content.length > 0);

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
        reply: {
          type: "string",
          description:
            "Natural conversational reply mainly in the selected target language.",
        },
        correction: {
          type: "string",
          description:
            "A natural corrected version of the learner's message when useful; otherwise an empty string.",
        },
        explanation: {
          type: "string",
          description:
            "Brief Traditional Chinese explanation of a correction or one useful language point.",
        },
        translation: {
          type: "string",
          description:
            "Natural Traditional Chinese translation of the coach reply.",
        },
        suggestions: {
          type: "array",
          minItems: 3,
          maxItems: 3,
          description:
            "Exactly three natural next things the learner could say, based on the current conversation.",
          items: {
            type: "object",
            additionalProperties: false,
            properties: {
              text: {
                type: "string",
                description:
                  "A concise next learner message in the selected target language.",
              },
              chinese: {
                type: "string",
                description:
                  "Natural Traditional Chinese meaning of the suggested learner message.",
              },
            },
            required: ["text", "chinese"],
          },
        },
        vocabulary: {
          type: "array",
          minItems: 3,
          maxItems: 3,
          description:
            "Exactly three useful vocabulary items or short phrases relevant to this conversation.",
          items: {
            type: "object",
            additionalProperties: false,
            properties: {
              term: {
                type: "string",
                description:
                  "A useful word or short phrase in the selected target language.",
              },
              chinese: {
                type: "string",
                description:
                  "Concise Traditional Chinese meaning.",
              },
              example: {
                type: "string",
                description:
                  "A short natural example sentence in the selected target language.",
              },
              exampleChinese: {
                type: "string",
                description:
                  "Natural Traditional Chinese translation of the example.",
              },
            },
            required: ["term", "chinese", "example", "exampleChinese"],
          },
        },
        grammar: {
          type: "object",
          additionalProperties: false,
          properties: {
            title: {
              type: "string",
              description:
                "Short practical grammar topic title in Traditional Chinese.",
            },
            explanation: {
              type: "string",
              description:
                "Concise practical grammar explanation in Traditional Chinese.",
            },
            question: {
              type: "string",
              description:
                "One short fill-in-the-blank practice question in the selected target language.",
            },
            choices: {
              type: "array",
              minItems: 3,
              maxItems: 3,
              items: { type: "string" },
            },
            answerIndex: {
              type: "integer",
              minimum: 0,
              maximum: 2,
              description:
                "Zero-based index of the correct choice.",
            },
            answerExplanation: {
              type: "string",
              description:
                "Traditional Chinese explanation of why the correct answer fits.",
            },
          },
          required: [
            "title",
            "explanation",
            "question",
            "choices",
            "answerIndex",
            "answerExplanation",
          ],
        },
      },
      required: [
        "reply",
        "correction",
        "explanation",
        "translation",
        "suggestions",
        "vocabulary",
        "grammar",
      ],
    };

    const transcript = history
      .map((item: { role: string; content: string }) =>
        `${item.role}: ${item.content}`
      )
      .join("\n");

    const prompt = [
      "You are Shili (汐璃), LinguaMate's warm multilingual conversation coach for a Traditional Chinese speaking learner.",
      "Shili should feel like a friendly, attentive practice partner rather than a textbook teacher.",
      "Her personality is gentle, natural, encouraging, lightly playful, and emotionally warm without being overly enthusiastic or clingy.",
      "Avoid robotic phrases, canned praise, repeated greetings, lecture-like explanations, and overly formal wording.",
      `Target practice language: ${targetLanguage}.`,
      `Conversation scenario: ${scenario}.`,
      isRoleplayMission
        ? "This is a role-play mission. Read the mission details from the scenario, stay consistently in Shili's assigned role, and make the learner accomplish the stated goal through realistic back-and-forth. Do not step out of character unless a brief correction is necessary. Ask only one natural next question or request at a time."
        : scenario === "日常生活"
          ? "Keep the conversation grounded in everyday routines, food, errands, family, hobbies, and casual daily interactions."
          : scenario === "工作職場"
            ? "Use realistic workplace situations such as meetings, reporting progress, asking for help, explaining problems, schedules, quality issues, and polite professional small talk."
            : scenario === "旅行"
              ? "Use realistic travel situations such as airports, hotels, transport, restaurants, directions, shopping, and asking locals for help."
              : "Let the learner choose the topic freely and follow their lead.",
      "The learner may write in Chinese, English, Tagalog, or Taglish.",
      learnerMemory
        ? `Learner memory: ${learnerMemory}. Use this only to personalize difficulty, prioritize weak areas, and avoid reteaching material the learner has already mastered.`
        : "",
      "reply: respond mainly in the selected target language. Keep it natural and conversational, usually 1-3 short sentences. React to what the learner actually said before asking a soft follow-up question when appropriate.",
      "Use contractions, everyday phrasing, and natural conversational rhythm when appropriate.",
      "correction: only correct a meaningful grammar or naturalness issue. Give one best natural version; otherwise return an empty string. Do not nitpick tiny mistakes.",
      "explanation: explain only the most useful point in warm, concise Traditional Chinese. Prefer practical usage over grammar terminology.",
      "translation: provide a natural Traditional Chinese translation of Shili's reply.",
      "suggestions: always provide exactly 3 short, distinct, useful things the learner could naturally say NEXT after Shili's reply. They must follow the actual conversation context, not generic topic prompts. Keep each suggestion concise, mainly in the selected target language, and include a natural Traditional Chinese meaning. Vary the intent across the three suggestions when possible, such as answering Shili, adding detail, asking a follow-up, clarifying, or moving the situation forward.",
      "vocabulary: always provide exactly 3 useful words or short phrases that help the learner expand vocabulary for THIS conversation. Prefer common, reusable language that is one small step beyond the learner's wording rather than obscure vocabulary. Avoid duplicates. For each item include the target-language term, concise Traditional Chinese meaning, a short natural example, and its Traditional Chinese translation.",
      "grammar: always provide one practical grammar pattern connected to the learner's sentence or the current scenario. If the learner made a grammar error, reinforce that pattern; otherwise teach one immediately useful pattern for saying more. Keep the explanation concise in Traditional Chinese. Include one short fill-in-the-blank question with exactly 3 choices, a zero-based answerIndex, and a concise Traditional Chinese answer explanation.",
      "For English, prefer natural spoken English over textbook English.",
      "For Tagalog, prefer everyday Filipino usage. For Taglish, mix English and Tagalog naturally as people commonly do in casual conversation.",
      "If the learner sounds tired, unsure, excited, or casual, lightly match that tone while still helping them practice.",
      "Never say you are correcting everything. Keep the conversation flowing first, teaching second.",
      "",
      transcript ? "Recent conversation:" : "",
      transcript,
      "",
      "Learner message:",
      message,
    ].filter(Boolean).join("\n");

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
        max_output_tokens: 2000,
        input: prompt,
        text: {
          format: {
            type: "json_schema",
            name: "linguamate_chat_reply",
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
          message: "AI 對話暫時失敗，請稍後再試。",
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

    let reply: unknown;
    try {
      reply = JSON.parse(outputText);
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

    return jsonResponse({ reply }, 200, origin);
  } catch (error) {
    console.error("LinguaMate chat error", error);
    return jsonResponse(
      {
        error: "INTERNAL_ERROR",
        message: "AI 對話時發生錯誤，請稍後再試。",
      },
      500,
      origin,
    );
  }
});