"""tools/textrules.py: rules every Japanese text must follow (used by check.py and reports.py).

Style source: WoW Forever Japanese (github.com/zyaga/wow-forever-japanese) docs/content/translation-style-guide.md
and pipeline/translation_glossary.tsv: names stay in English letters, class words in glossary katakana, and
ForeverSensei's own tone rule: friendly plain form (no です・ます).
"""
import re

# Names that are not spells or talents but still stay in English letters when the English text has them.
EXTRA_NAMES = [
    "ForeverSensei", "Skyborne", "Windshaper", "Wind Blessed", "Skysight", "Walk on Air", "Charged", "Mobalytics", "Wowhead",
    "Hearthstone", "Restoration", "Enhancement", "Elemental", "Dual Specialization", "Talented Legacy",
    "Improved Ghost Wolf", "Call of Earth", "Call of Fire", "Call of Water", "Call of Air", "Forever",
    "Ctrl+C", "Shift", "/sensei",
    "Protection", "Retribution", "Forbearance", "Symbol of Divinity", "Symbol of Kings", "Anticipation",
]

# English word (regex, case-insensitive) → Japanese that must appear. Glossary terms (WFJ) and our UI terms.
REQUIRED_TERMS = [
    (r"\bshamans?\b", "シャーマン"),
    (r"\bpaladins?\b", "パラディン"),
    (r"\btrainers?\b", "トレーナー"),
    (r"\btotems?\b", "トーテム"),
    (r"\btalents?\b", "タレント"),
    (r"\baction bars?\b", "アクションバー"),
    (r"\bmouseover\b", "マウスオーバー"),
    (r"\bquests?\b|\bquesting\b", "クエスト"),
]

# WFJ settled terms: never these renderings.
FORBIDDEN_TERMS = {
    "ヘルス": "use 体力 (WFJ)",
    "知性": "use 知力 (WFJ)",
    "役割": "use ロール for role (WFJ)",
}

POLITE = re.compile(r"です|ます|でした|ました|ください|ません|でしょう")
PLACEHOLDER = re.compile(r"\{(\w+)\}")
EXTRA_GLYPHS = set("→●○・…〜")

# Longest texts we allow (characters). Skill card fields are shown in a fixed-width card.
MAX_LEN = {"spell.": 110, "talent.": 200, "guide.": 200, "ui.": 160}


def max_len(text_id):
    for prefix, n in MAX_LEN.items():
        if text_id.startswith(prefix):
            return n
    return 160


def glyph_ok(ch):
    o = ord(ch)
    return (
        0x20 <= o < 0x7F
        or 0x3000 <= o <= 0x30FF  # CJK punctuation, hiragana, katakana
        or 0x4E00 <= o <= 0x9FFF  # CJK ideographs
        or 0xFF01 <= o <= 0xFF5E  # full-width forms
        or ch in EXTRA_GLYPHS
    )


def names_problems(en, ja, names):
    """Every name in the English must appear unchanged in the Japanese. Longest names are matched first."""
    out = []
    en_m, ja_m = en, ja
    for name in sorted(set(names), key=len, reverse=True):
        if name in en_m:
            if name not in ja_m:
                out.append(f"name '{name}' must stay in English letters")
            en_m = en_m.replace(name, "\0")
            ja_m = ja_m.replace(name, "\0")
    return out


def ja_problems(text_id, ja, en, names):
    """→ list of problems (empty when the Japanese follows the rules)."""
    out = []
    if not isinstance(ja, str) or not ja.strip():
        return ["empty Japanese"]
    if POLITE.search(ja):
        out.append(f"polite form '{POLITE.search(ja).group(0)}' (use plain form)")
    rest = re.sub(r"/sensei(\s+\w+)?", "", ja)
    if "/" in rest:
        out.append("'/' (write the words out, or use ・)")
    if "..." in ja or re.search(r"(?<!…)…(?!…)", ja):
        out.append("ellipsis (use …… if needed)")
    if "\n" in ja:
        out.append("line break (texts wrap by themselves)")
    bad = sorted({c for c in ja if c != "\n" and not glyph_ok(c)})
    if bad:
        out.append("glyphs the font may lack: " + " ".join(f"U+{ord(c):04X}" for c in bad))
    if sorted(PLACEHOLDER.findall(ja)) != sorted(PLACEHOLDER.findall(en or "")):
        out.append(f"placeholders differ from English: {sorted(PLACEHOLDER.findall(en or ''))}")
    if en:
        out += names_problems(en, ja, list(names) + EXTRA_NAMES)
        en_wo_names = en
        for name in sorted(set(list(names) + EXTRA_NAMES), key=len, reverse=True):
            en_wo_names = en_wo_names.replace(name, " ")
        for pattern, term in REQUIRED_TERMS:
            if re.search(pattern, en_wo_names, re.I) and term not in ja:
                out.append(f"English '{re.sub(r'[^a-z ]', '', pattern.split('|')[0].replace('s?', ''))}' must be {term}")
    for term, why in FORBIDDEN_TERMS.items():
        if term in ja:
            out.append(f"'{term}': {why}")
    if len(ja) > max_len(text_id):
        out.append(f"too long ({len(ja)} > {max_len(text_id)} characters)")
    return out
