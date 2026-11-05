// Supabase Edge Function: ai-advisor
// Securely processes financial advice requests with OpenAI API without exposing keys on the mobile client.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface FinancialContext {
  monthlyIncome: number;
  monthlyExpenses: number;
  topCategories: { category: string; amount: number }[];
  budgetAlerts: string[];
  recentTransactionsSummary: string;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Missing authorization header" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_ANON_KEY") ?? "",
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized user" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { prompt, context }: { prompt: string; context: FinancialContext } = await req.json();

    const openAiKey = Deno.env.get("OPENAI_API_KEY");
    if (!openAiKey) {
      // Fallback response if environment key is not configured
      return new Response(
        JSON.stringify({
          reply: `Based on your monthly income of $${context.monthlyIncome.toFixed(2)} and current expenses of $${context.monthlyExpenses.toFixed(2)}, your current savings rate is ${(((context.monthlyIncome - context.monthlyExpenses) / (context.monthlyIncome || 1)) * 100).toFixed(1)}%. Focusing on reducing ${context.topCategories[0]?.category || "top spending"} could save you an estimated $120-$250 this month.`,
          disclaimer: "Educational suggestions only. Not guaranteed financial advice.",
        }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const systemPrompt = `You are NEXORA, an intelligent, empathetic fintech advisor.
The user is asking: "${prompt}"
Authorized Financial Context:
- Monthly Income: $${context.monthlyIncome}
- Monthly Expenses: $${context.monthlyExpenses}
- Top Categories: ${JSON.stringify(context.topCategories)}
- Budget Alerts: ${JSON.stringify(context.budgetAlerts)}
- Recent Summary: ${context.recentTransactionsSummary}

Provide concise, highly actionable, encouraging, and accurate financial advice.
Always include the disclaimer that educational suggestions are not professional financial or guaranteed investment advice. Keep responses under 150 words.`;

    const openAiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${openAiKey}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: prompt },
        ],
        temperature: 0.7,
        max_tokens: 300,
      }),
    });

    const aiData = await openAiResponse.json();
    const reply = aiData.choices?.[0]?.message?.content ?? "I could not generate an answer right now.";

    return new Response(
      JSON.stringify({
        reply,
        disclaimer: "Educational suggestions only. Not guaranteed financial advice.",
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err: any) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});

