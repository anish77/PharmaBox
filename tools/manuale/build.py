"""Build the illustrated Italian user manual as PDF and standalone HTML.

Install tools/manuale/requirements.txt, then run this script from any folder.
The Markdown and original screenshots are the only content sources.
"""
from pathlib import Path
import base64
import html
import re
import xml.etree.ElementTree as ET

import markdown
from PIL import Image as PILImage
from reportlab.lib import colors
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    BaseDocTemplate, Frame, Image, KeepTogether, PageBreak, PageTemplate,
    Paragraph, Spacer, Table, TableStyle,
)
from reportlab.platypus.tableofcontents import TableOfContents

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs/manuale-utente'
SOURCE = OUT / 'Manuale-PharmaBox.md'
PURPLE = colors.HexColor('#5D5FEF')
INK = colors.HexColor('#2B2D66')
WIDTH = A4[0] - 36 * mm


def build_html(body):
    # Embed originals so the HTML can be moved or emailed as one file.
    def embed(match):
        path = OUT / match.group(1)
        alt = match.group(2)
        data = base64.b64encode(path.read_bytes()).decode()
        return (f'<figure><a href="data:image/png;base64,{data}" target="_blank" '
                f'aria-label="Apri immagine a grandezza originale">'
                f'<img src="data:image/png;base64,{data}" alt="{alt}" loading="lazy" />'
                f'</a><figcaption>{alt}</figcaption></figure>')
    body = re.sub(r'<img alt="([^"]*)" src="([^"]*)"\s*/>',
                  lambda m: f'<img src="{m[2]}" alt="{m[1]}" />', body)
    body = re.sub(r'<p>(<img[^>]+/>)</p>', r'\1', body)
    body = re.sub(r'<img src="([^"]*)" alt="([^"]*)"\s*/>', embed, body)
    css = """
    :root {--ink:#2b2d66;--purple:#5d5fef;--bg:#f5f7fa}
    *{box-sizing:border-box} html{scroll-behavior:smooth}
    body{margin:0;background:var(--bg);color:#27304a;font:17px/1.7 system-ui,sans-serif}
    main{max-width:960px;margin:32px auto;padding:54px 70px;background:white;border-radius:20px}
    h1{font-size:64px;color:var(--purple);margin-bottom:0;letter-spacing:-3px}
    h2{font-size:29px;line-height:1.25;color:var(--ink);border-top:2px solid #e5e6ff;padding-top:36px;margin-top:60px;scroll-margin-top:30px}
    h3{color:var(--ink);margin-top:32px} a{color:#4444c6} li{margin:8px 0}
    table{border-collapse:collapse;width:100%;font-size:15px;margin:24px 0}
    th,td{padding:12px 14px;border:1px solid #dde0f0;text-align:left;vertical-align:top}
    th{background:#e5e6ff;color:var(--ink)} tr:nth-child(even){background:#f8f9fc}
    figure{text-align:center;margin:35px 0;padding:25px;background:#f5f7fa;border-radius:16px;break-inside:avoid}
    figure img{max-width:100%;width:310px;height:auto;border:1px solid #dde0f0;border-radius:12px}
    figcaption{font-size:14px;color:#5d6480;margin-top:15px}
    .toc{background:#f0f0ff;padding:25px 35px;border-radius:14px;margin:35px 0;font-size:15px}
    .toc>ul{padding-left:20px;columns:2;column-gap:35px}.toc li{break-inside:avoid}
    .toc a{text-decoration:none}.toc a:hover{text-decoration:underline}
    .tools{position:sticky;top:0;display:flex;justify-content:flex-end;gap:12px;background:#f5f7faee;padding:10px 24px;z-index:1}
    button{background:var(--purple);color:white;border:0;border-radius:8px;padding:10px 16px;font:inherit;cursor:pointer}
    .toplink{align-self:center;font-size:14px}.subtitle{font-size:25px;color:var(--ink)}
    @media(max-width:700px){main{margin:0;padding:25px 22px;border-radius:0}h1{font-size:45px}h2{font-size:25px}.toc>ul{columns:1}table{font-size:13px}td,th{padding:8px}}
    @media print{body{background:white;font-size:10pt}.tools{display:none}main{max-width:none;margin:0;padding:0}h1{font-size:38pt}h2{break-before:page;border:0;margin:0;padding:0}h3{break-after:avoid}figure img{width:48mm}.toc>ul{columns:1}figure{padding:4mm}table{font-size:9pt}a{color:inherit}}
    """
    doc = f'''<!doctype html><html lang="it"><head><meta charset="utf-8">
    <meta name="viewport" content="width=device-width,initial-scale=1">
    <title>PharmaBox — Manuale utente completo</title><style>{css}</style></head>
    <body id="inizio"><div class="tools"><a class="toplink" href="#indice">Indice</a>
    <button onclick="window.print()">Stampa / Salva PDF</button></div><main>{body}</main></body></html>'''
    (OUT / 'Manuale-PharmaBox.html').write_text(doc, encoding='utf-8')


def styles():
    pdfmetrics.registerFont(TTFont('Roboto', str(ROOT / 'assets/fonts/Roboto-Regular.ttf')))
    pdfmetrics.registerFont(TTFont('Roboto-Bold', str(ROOT / 'assets/fonts/Roboto-Bold.ttf')))
    pdfmetrics.registerFontFamily('Roboto', normal='Roboto', bold='Roboto-Bold', italic='Roboto', boldItalic='Roboto-Bold')
    ss = getSampleStyleSheet()
    ss.add(ParagraphStyle('Text', fontName='Roboto', fontSize=10.2, leading=15.4,
                          textColor=INK, spaceAfter=8))
    ss.add(ParagraphStyle('Chapter', parent=ss['Text'], fontName='Roboto-Bold',
                          fontSize=21, leading=26, spaceAfter=18, keepWithNext=True))
    ss.add(ParagraphStyle('Subhead', parent=ss['Text'], fontName='Roboto-Bold',
                          fontSize=13, leading=18, spaceBefore=12, spaceAfter=8, keepWithNext=True))
    ss.add(ParagraphStyle('Caption', parent=ss['Text'], fontSize=8.5, leading=12,
                          alignment=TA_CENTER, textColor=colors.HexColor('#666c83')))
    ss.add(ParagraphStyle('Cell', parent=ss['Text'], fontSize=8.5, leading=12, spaceAfter=0))
    ss.add(ParagraphStyle('ListItem', parent=ss['Text'], leftIndent=15, firstLineIndent=-11,
                          spaceAfter=6))
    ss.add(ParagraphStyle('CoverTitle', parent=ss['Text'], fontName='Roboto-Bold',
                          fontSize=45, leading=52, textColor=PURPLE, spaceAfter=18))
    ss.add(ParagraphStyle('CoverSub', parent=ss['Text'], fontSize=25, leading=32, spaceAfter=24))
    return ss


class ManualDoc(BaseDocTemplate):
    def __init__(self, path):
        super().__init__(str(path), pagesize=A4, leftMargin=18*mm, rightMargin=18*mm,
                         topMargin=20*mm, bottomMargin=19*mm,
                         title='PharmaBox — Manuale utente completo', author='PharmaBox',
                         subject='Manuale italiano illustrato, versione 1.0.2+2')
        frame = Frame(self.leftMargin, self.bottomMargin, self.width, self.height,
                      leftPadding=0, rightPadding=0, topPadding=0, bottomPadding=0)
        self.addPageTemplates(PageTemplate(id='normal', frames=frame, onPage=self.page_art))

    def page_art(self, canvas, doc):
        canvas.saveState()
        canvas.setFillColor(PURPLE)
        canvas.rect(0, A4[1]-5*mm, A4[0], 5*mm, fill=1, stroke=0)
        canvas.setFont('Roboto', 8)
        canvas.setFillColor(INK)
        if doc.page > 1:
            canvas.drawString(18*mm, A4[1]-13*mm, 'PHARMABOX  /  MANUALE UTENTE')
            canvas.drawRightString(A4[0]-18*mm, A4[1]-13*mm, 'Edizione 12 ottobre 2026')
        canvas.setStrokeColor(colors.HexColor('#e5e6ff'))
        canvas.line(18*mm, 14*mm, A4[0]-18*mm, 14*mm)
        canvas.drawString(18*mm, 9*mm, 'Versione di riferimento 1.0.2+2')
        canvas.drawRightString(A4[0]-18*mm, 9*mm, str(doc.page))
        canvas.restoreState()

    def afterFlowable(self, flowable):
        if isinstance(flowable, Paragraph) and hasattr(flowable, 'bookmark'):
            title = flowable.getPlainText()
            key = flowable.bookmark
            self.canv.bookmarkPage(key)
            self.canv.addOutlineEntry(title, key, level=0)
            self.notify('TOCEntry', (0, title, self.page, key))


def inline(el):
    result = html.escape(el.text or '')
    for child in el:
        content = inline(child)
        if child.tag == 'strong':
            result += f'<b>{content}</b>'
        elif child.tag == 'em':
            result += f'<i>{content}</i>'
        elif child.tag == 'code':
            result += f'<font color="#4444bb">{content}</font>'
        elif child.tag == 'a':
            result += f'<link href="{html.escape(child.get("href", ""), quote=True)}" color="#4444bb"><u>{content}</u></link>'
        elif child.tag == 'br':
            result += '<br/>'
        else:
            result += content
        result += html.escape(child.tail or '')
    return result


def build_pdf(raw):
    ss = styles()
    root = ET.fromstring('<root>' + markdown.markdown(raw, extensions=['tables']) + '</root>')
    flow = [Spacer(1, 22*mm), Image(str(ROOT / 'assets/Logo.png'), 30*mm, 30*mm, hAlign='LEFT'),
            Spacer(1, 15*mm), Paragraph('PharmaBox', ss['CoverTitle']),
            Paragraph('Manuale utente<br/>completo', ss['CoverSub']),
            Paragraph('Dall’accesso al primo inventario, fino all’esportazione e alla gestione dell’account.', ss['Text']),
            Spacer(1, 12*mm), Paragraph('23 capitoli · Screenshot dell’app · Procedure passo passo', ss['Subhead']),
            Paragraph('Edizione 12 ottobre 2026<br/>Versione di riferimento 1.0.2+2', ss['Text']),
            Spacer(1, 20*mm), Paragraph('Una guida operativa per il lavoro quotidiano in farmacia.', ss['Text']),
            PageBreak(), Paragraph('Indice', ss['Chapter'])]
    toc = TableOfContents()
    toc.levelStyles = [ParagraphStyle('TOC', fontName='Roboto', fontSize=9.5, leading=13,
                                     textColor=INK, spaceBefore=2, rightIndent=20)]
    flow.append(toc)
    started = False
    for el in root:
        if el.tag == 'h2':
            started = True
            flow.append(PageBreak())
            p = Paragraph(inline(el), ss['Chapter'])
            p.bookmark = 'chapter-' + str(len([f for f in flow if hasattr(f, 'bookmark')]) + 1)
            flow.append(p)
        elif not started:
            continue
        elif el.tag == 'h3':
            flow.append(Paragraph(inline(el), ss['Subhead']))
        elif el.tag == 'p':
            picture = el.find('img')
            if picture is not None:
                path = OUT / picture.get('src')
                with PILImage.open(path) as im:
                    iw, ih = im.size
                height = 180*mm
                width = height * iw / ih
                flow.append(KeepTogether([
                    Spacer(1, 6*mm), Image(str(path), width, height), Spacer(1, 3*mm),
                    Paragraph(html.escape(picture.get('alt', '')), ss['Caption']),
                    Spacer(1, 4*mm),
                ]))
            else:
                flow.append(Paragraph(inline(el), ss['Text']))
        elif el.tag in ('ul', 'ol'):
            for i, li in enumerate(el.findall('li'), 1):
                mark = f'{i}.' if el.tag == 'ol' else '•'
                flow.append(Paragraph(f'{mark}  {inline(li)}', ss['ListItem']))
        elif el.tag == 'table':
            rows = []
            for tr in el.findall('.//tr'):
                row = [Paragraph(('<b>' if c.tag == 'th' else '') + inline(c) + ('</b>' if c.tag == 'th' else ''), ss['Cell']) for c in tr]
                rows.append(row)
            n = len(rows[0])
            widths = [WIDTH*.34, WIDTH*.66] if n == 2 else [WIDTH*.22, WIDTH*.33, WIDTH*.45]
            table = Table(rows, colWidths=widths, repeatRows=1, hAlign='LEFT')
            table.setStyle(TableStyle([
                ('BACKGROUND', (0,0), (-1,0), colors.HexColor('#e5e6ff')),
                ('ROWBACKGROUNDS', (0,1), (-1,-1), [colors.white, colors.HexColor('#f5f7fa')]),
                ('GRID', (0,0), (-1,-1), .4, colors.HexColor('#d9ddeb')),
                ('VALIGN', (0,0), (-1,-1), 'TOP'),
                ('LEFTPADDING', (0,0), (-1,-1), 8), ('RIGHTPADDING', (0,0), (-1,-1), 8),
                ('TOPPADDING', (0,0), (-1,-1), 7), ('BOTTOMPADDING', (0,0), (-1,-1), 7),
            ]))
            flow.extend([Spacer(1, 3*mm), table, Spacer(1, 4*mm)])
    # Short illustrated chapters place instructions beside the screenshot.
    # Longer chapters and full-width tables retain the normal reading order.
    compact = []
    start = 0
    breaks = [i for i, f in enumerate(flow) if isinstance(f, PageBreak)] + [len(flow)]
    for end in breaks:
        section = flow[start:end]
        pictures = [f for f in section if isinstance(f, KeepTogether)]
        if (section and isinstance(section[0], Paragraph)
                and hasattr(section[0], 'bookmark') and len(pictures) == 1
                and section[-1] is pictures[0]
                and all(isinstance(f, Paragraph) for f in section[1:-1])):
            instructions = section[1:-1]
            left_width = 96*mm
            height = sum(f.wrap(left_width, 10000)[1] + f.getSpaceBefore()
                         + f.getSpaceAfter() for f in instructions)
            if height < 220*mm:
                original = next(f for f in pictures[0]._content if isinstance(f, Image))
                caption = next(f for f in pictures[0]._content if isinstance(f, Paragraph))
                iw = 70*mm
                ih = iw * original.imageHeight / original.imageWidth
                pic = [Image(original.filename, iw, ih), Spacer(1, 3*mm), caption]
                layout = Table([[instructions, pic]], colWidths=[102*mm, 72*mm])
                layout.setStyle(TableStyle([
                    ('VALIGN', (0,0), (-1,-1), 'TOP'),
                    ('LEFTPADDING', (0,0), (-1,-1), 0),
                    ('RIGHTPADDING', (0,0), (0,0), 6*mm),
                    ('RIGHTPADDING', (1,0), (1,0), 0),
                    ('TOPPADDING', (0,0), (-1,-1), 0),
                    ('BOTTOMPADDING', (0,0), (-1,-1), 0),
                ]))
                section = [section[0], layout]
        compact.extend(section)
        if end < len(flow):
            compact.append(flow[end])
        start = end + 1
    ManualDoc(OUT / 'Manuale-PharmaBox.pdf').multiBuild(compact)


def main():
    raw = SOURCE.read_text(encoding='utf-8')
    for ref in re.findall(r'!\[[^\]]*\]\(([^)]+)\)', raw):
        if not (OUT / ref).is_file():
            raise FileNotFoundError(ref)
    md = markdown.Markdown(extensions=['tables', 'toc'], extension_configs={'toc': {'toc_depth': '2-2'}})
    body = md.convert(raw)
    first = body.index('<h2')
    body = body[:first] + '<div id="indice"><h2>Indice</h2>' + md.toc + '</div>' + body[first:]
    build_html(body)
    build_pdf(raw)
    print('Created Manuale-PharmaBox.pdf and Manuale-PharmaBox.html')


if __name__ == '__main__':
    main()
