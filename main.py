from fastapi import FastAPI
from pydantic import BaseModel
import spacy
from demorphy import Analyzer

app = FastAPI()
nlp = spacy.load("de_core_news_md")
morph = Analyzer(char_subs_allowed=True)


class SentenceRequest(BaseModel):
    text: str


class WordRequest(BaseModel):
    word: str
    context: str | None = None


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/analyze/sentence")
def analyze_sentence(req: SentenceRequest):
    doc = nlp(req.text)
    return {
        "tokens": [
            {
                "text": t.text,
                "lemma": t.lemma_,
                "pos": t.pos_,          # NOUN, VERB, ADJ ...
                "tag": t.tag_,          # NN, VVFIN, ADJA ...
                "dep": t.dep_,          # sb, oa, mo ...
                "morph": str(t.morph),  # Case=Acc|Gender=Masc|Number=Sing
                "is_stop": t.is_stop,
            }
            for t in doc
        ]
    }


@app.post("/analyze/word")
def analyze_word(req: WordRequest):
    # DEMorphy: all possible morphological forms
    demorphy_analyses = []
    try:
        analyses = morph.analyze(req.word)
        demorphy_analyses = [str(a) for a in analyses]
    except Exception:
        pass

    # spaCy in context if provided
    spacy_result = None
    if req.context:
        doc = nlp(req.context)
        for token in doc:
            if token.text.lower() == req.word.lower():
                spacy_result = {
                    "lemma": token.lemma_,
                    "pos": token.pos_,
                    "tag": token.tag_,
                    "morph": str(token.morph),
                }
                break

    return {
        "word": req.word,
        "spacy": spacy_result,
        "demorphy": demorphy_analyses,
    }
