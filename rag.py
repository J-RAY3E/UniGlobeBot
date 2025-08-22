import pickle
import faiss
import os
from fastapi import FastAPI
from pydantic import BaseModel
from sentence_transformers import SentenceTransformer
from yandex_cloud_ml_sdk import YCloudML

# Configuración
BUCKET_NAME = "rag-vectorstore-1755763542"  # Ya no se usa para runtime
MODEL_NAME = "./models/all-MiniLM-L6-v2"
VECTORSTORE_DIR = "/app/vectorstore"
TOP_K = 3

# Variables globales
index = None
metadata = None
model = None
yc_model = None

# Inicializar vectorstore desde carpeta local
def load_vectorstore():
    faiss_path = os.path.join(VECTORSTORE_DIR, "vectorstore.faiss")
    meta_path = os.path.join(VECTORSTORE_DIR, "vectorstore_meta.pkl")
    
    index = faiss.read_index(faiss_path)
    with open(meta_path, "rb") as f:
        metadata = pickle.load(f)
    
    print("Vectorstore cargado exitosamente!")
    return index, metadata

# Inicializar app
def initialize_app():
    global index, metadata, model, yc_model
    
    print("Iniciando carga de vectorstore...")
    index, metadata = load_vectorstore()
    model = SentenceTransformer(MODEL_NAME)
    
    # Configuración Yandex GPT
    token = os.getenv("YANDEX_TOKEN")
    if token:
        sdk = YCloudML(folder_id="b1go6qinn0muj8gb8k4o", auth=token)
        yc_model = sdk.models.completions("yandexgpt-32k", model_version="latest")
        yc_model = yc_model.configure(temperature=0.3)
        print("Yandex GPT configurado exitosamente!")
    else:
        print("⚠️  YANDEX_TOKEN no encontrado")

app = FastAPI()

@app.on_event("startup")
async def startup_event():
    initialize_app()

class QuestionRequest(BaseModel):
    question: str
    top_k: int = TOP_K

def query_rag(question, k=TOP_K):
    if index is None or metadata is None:
        return "Error: Vectorstore no cargado"
    
    q_emb = model.encode([question], convert_to_numpy=True)
    D, I = index.search(q_emb, k)
    context = ""
    for i in I[0]:
        chunk = metadata[i]["text_snippet"]
        context += f"{chunk}\n\n"
    return context

def ask_yandex(question):
    if yc_model is None:
        return "Error: Yandex GPT no configurado"
    
    context = query_rag(question)
    behavior = """
    You are an expert assistant specialized in topics related to settling abroad as an international student.
    Answer all questions in English clearly and concisely. Use the context provided to give accurate advice.
    """
    user_input = f"Context:\n{context}\n\nQuestion: {question}"
    result = yc_model.run(
        [
            {"role": "system", "text": behavior},
            {"role": "user", "text": user_input}
        ]
    )
    return result.alternatives[0].text if result else ""

@app.get("/")
def root():
    return {"status": "RAG + Yandex GPT service running"}

@app.get("/health")
def health_check():
    status = {
        "vectorstore_loaded": index is not None,
        "model_loaded": model is not None,
        "yandex_configured": yc_model is not None
    }
    return status

@app.post("/ask")
def ask(req: QuestionRequest):
    answer = ask_yandex(req.question)
    return {"answer": answer}

if __name__ == "__main__":
    import uvicorn
    port = int(os.environ.get("PORT", 8080))
    uvicorn.run(app, host="0.0.0.0", port=port, workers=1, reload=False)

