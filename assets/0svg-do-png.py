import os
import re

# --- KONFIGURACJA ---
FOLDER_ASSETS = r"C:\Users\mateu\Documents\zombs-reborn\assets"
# ---------------------

def uruchom_automat_playwright():
    try:
        from playwright.sync_api import sync_playwright
    except ImportError:
        print("[BLAD KRYTYCZNY] Biblioteka Playwright nie jest zainstalowana!")
        print("Wpisz w konsoli: pip install playwright && playwright install chromium")
        return

    folder_png = os.path.join(FOLDER_ASSETS, "png")
    if not os.path.exists(folder_png):
        os.makedirs(folder_png)

    pliki = [f for f in os.listdir(FOLDER_ASSETS) if f.lower().endswith('.svg')]
    if not pliki:
        print(f"Brak plików .svg w folderze: {FOLDER_ASSETS}")
        return

    print("=" * 60)
    print("   MASOWY KONWERTER ZOMBS.IO (PLAYWRIGHT) - 128x128 + ALFA   ")
    print("=" * 60)
    print(f"Znaleziono {len(pliki)} plików. Uruchamiam zautomatyzowany silnik...\n")

    # Uruchamiamy Playwright (narzędzie do automatyzacji)
    with sync_playwright() as p:
        # headless=True oznacza, że wszystko dzieje się w tle
        browser = p.chromium.launch(headless=True)
        page = browser.new_page()

        udane = 0
        for plik in pliki:
            sciezka_svg = os.path.join(FOLDER_ASSETS, plik)
            sciezka_png = os.path.join(folder_png, os.path.splitext(plik)[0] + ".png")

            try:
                # Wczytujemy surowy kod pliku SVG
                with open(sciezka_svg, "r", encoding="utf-8") as f:
                    svg_kod = f.read()

                # Zabezpieczenie przed "ucinaniem" wieżyczek (brak viewBox w plikach zombs.io)
                if "viewBox" not in svg_kod:
                    w_match = re.search(r'width=["\']([\d\.]+)px["\']', svg_kod)
                    h_match = re.search(r'height=["\']([\d\.]+)px["\']', svg_kod)
                    if w_match and h_match:
                        w, h = w_match.group(1), h_match.group(1)
                        svg_kod = svg_kod.replace("<svg", f'<svg viewBox="0 0 {w} {h}"', 1)

                # Wstrzykujemy grafikę do idealnego kontenera 128x128
                # Używamy CSS Flexbox, żeby środek wieżyczki zawsze był w centrum kwadratu
                html_content = f"""
                <!DOCTYPE html>
                <html>
                <body style="margin: 0; padding: 0; background: transparent;">
                    <div id="render-box" style="width: 128px; height: 128px; display: flex; justify-content: center; align-items: center;">
                        {svg_kod}
                    </div>
                    <script>
                        // Wymuszamy, aby grafika zachowała proporcje i nie wylała się poza 128px
                        const svg = document.querySelector('svg');
                        if (svg) {{
                            svg.style.maxWidth = '100%';
                            svg.style.maxHeight = '100%';
                            svg.style.width = 'auto';
                            svg.style.height = 'auto';
                        }}
                    </script>
                </body>
                </html>
                """
                
                # Przekazujemy kod do przeglądarki i czekamy, aż przetworzy style CSS
                page.set_content(html_content)
                
                # KLUCZOWY MOMENT: Wycinamy idealny kwadrat "render-box" do PNG.
                # omit_background=True gwarantuje, że białe tło zostaje wymazane - zostaje sama alfa (przezroczystość)!
                page.locator("#render-box").screenshot(path=sciezka_png, omit_background=True)
                
                print(f"[OK] Przekonwertowano: {plik}")
                udane += 1
                
            except Exception as e:
                print(f"[BLAD] Przy pliku {plik}: {e}")

        # Zamykamy proces po przerobieniu całego folderu
        browser.close()
        
        print("\n" + "=" * 60)
        print(f"GOTOWE! Pomyślnie zautomatyzowano konwersję {udane}/{len(pliki)} plików.")

if __name__ == "__main__":
    uruchom_automat_playwright()
    input("\nWciśnij ENTER, aby zakończyć...")