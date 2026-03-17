import ollama
from flask import Flask, render_template, request, stream_with_context, Response
import json

app = Flask(__name__)

@app.route("/")
def index():
    return render_template("index.html")

@app.route("/summarize", methods=["POST"])
def summarize():
    text = request.form.get("text", "").strip()
    model = request.form.get("model", "gemma3:4b").strip()
    mode = request.form.get("mode", "summarize").strip()

    if not text:
        return Response("data: [ERROR] No text provided.\n\n", mimetype="text/event-stream")

    prompts = {
        "summarize": f"Summarize the following text in a few clear sentences:\n\n{text}",
        "bullets":   f"Extract the key points from the text below as a concise bullet list:\n\n{text}",
        "actions":   f"List all action items and next steps from the text below. If there are none, suggest logical follow-ups:\n\n{text}",
    }

    prompt = prompts.get(mode, prompts["summarize"])

    def generate():
        try:
            stream = ollama.chat(
                model=model,
                messages=[{"role": "user", "content": prompt}],
                stream=True
            )
            for chunk in stream:
                token = chunk["message"]["content"]
                yield f"data: {json.dumps(token)}\n\n"
        except Exception as e:
            yield f"data: [ERROR] {str(e)}\n\n"
        yield "data: [DONE]\n\n"

    return Response(stream_with_context(generate()), mimetype="text/event-stream")


if __name__ == "__main__":
    app.run(debug=True, port=5000)