import sys
import zipfile
import xml.etree.ElementTree as ET


def extract_docx(path):
    with zipfile.ZipFile(path) as z:
        with z.open('word/document.xml') as f:
            tree = ET.parse(f)
    root = tree.getroot()
    # Word XML uses namespaces; find namespace
    ns = {'w': 'http://schemas.openxmlformats.org/wordprocessingml/2006/main'}
    paragraphs = []
    for para in root.findall('.//w:p', ns):
        texts = [node.text for node in para.findall('.//w:t', ns) if node.text]
        if texts:
            paragraphs.append(''.join(texts))
    return '\n\n'.join(paragraphs)


def main():
    if len(sys.argv) < 2:
        print('Usage: python extract_docx_text.py <path/to/file.docx>')
        sys.exit(1)
    path = sys.argv[1]
    try:
        text = extract_docx(path)
        print(text)
    except Exception as e:
        print('ERROR:', e, file=sys.stderr)
        sys.exit(2)


if __name__ == '__main__':
    main()
