import os
import sys
import re
import xml.etree.ElementTree as ET

# --- KONFIGURACJA ---
FOLDER_ASSETS = r"C:\Users\mateu\Documents\zombs-reborn\assets"
# ---------------------

def napraw_strukture_svg(sciezka_wejsciowa, sciezka_wyjsciowa):
    """Rozbija grupowe style CSS i wstrzykuje je jako czyste atrybuty wektorowe XML."""
    ET.register_namespace('', "http://www.w3.org/2000/svg")
    drzewo = ET.parse(sciezka_wejsciowa)
    korzen = drzewo.getroot()
    
    # Czyszczenie wymiarów z jednostek tekstowych typu 'px', które mylą Godota
    for attr in ['width', 'height']:
        if attr in korzen.attrib:
            korzen.attrib[attr] = korzen.attrib[attr].replace('px', '').strip()
            
    # Szukamy sekcji <style>
    style_element = None
    for el in korzen.iter():
        if el.tag.endswith('style'):
            style_element = el
            break
            
    baza_stylow = {}
    if style_element is not None and style_element.text:
        tekst_css = style_element.text
        
        # Wyciągamy bloki: selektory { właściwości }
        bloki = re.findall(r'([^{}]+)\s*\{([^}]+)\}', tekst_css)
        
        for selektory_raw, wlasnosci_raw in bloki:
            # Rozbijamy grupowe klasy (.cls-1, .cls-2 -> ['cls-1', 'cls-2'])
            selektory = [s.strip().lstrip('.') for s in selektory_raw.split(',')]
            
            # Wyciągamy cechy kolorów i obramowań
            pary = re.findall(r'([\w-]+)\s*:\s*([^;]+)', wlasnosci_raw)
            wlasnosci_dict = {cecha.strip(): wartosc.strip() for cecha, wartosc in pary}
            
            # Łączymy style dla każdej klasy osobno
            for klasa in selektory:
                if klasa not in baza_stylow:
                    baza_stylow[klasa] = {}
                baza_stylow[klasa].update(wlasnosci_dict)
        
        # Usuwamy tag <style>, bo przenosimy go do atrybutów obiektów
        for parent in korzen.iter():
            if style_element in parent:
                parent.remove(style_element)
                break
                
    # Wstrzykujemy czyste cechy bezpośrednio do każdego kształtu geometrycznego
    for element in korzen.iter():
        klasa = element.get('class')
        if klasa and klasa in baza_stylow:
            for cecha, wartosc in baza_stylow[klasa].items():
                # Silnik ThorVG w Godocie nie znosi słowa 'px' przy grubości linii
                if cecha == 'stroke-width':
                    wartosc = wartosc.replace('px', '').strip()
                element.set(cecha, wartosc)
            del element.attrib['class']
            
    # Zapisujemy jako w 100% kompatybilny plik wektorowy SVG
    drzewo.write(sciezka_wyjsciowa, encoding='utf-8', xml_declaration=True)

def main():
    print("=" * 60)
    print("    GODOT NATIVE SVG VECTOR REPAIRER (CSS INJECTOR)    ")
    print("=" * 60)

    if not os.path.exists(FOLDER_ASSETS):
        print(f"[BLAD] Folder assets nie istnieje:\n-> {FOLDER_ASSETS}")
        return

    # Tworzymy osobny folder na naprawione pliki wektorowe
    folder_wyjsciowy = os.path.join(FOLDER_ASSETS, "svg")
    if not os.path.exists(folder_wyjsciowy):
        os.makedirs(folder_wyjsciowy)
        print("[+] Utworzono folder: /svg")

    pliki = [f for f in os.listdir(FOLDER_ASSETS) if f.lower().endswith('.svg')]
    if not pliki:
        print("Nie znaleziono plików .svg do naprawy.")
        return

    print(f"Naprawianie {len(pliki)} plików wektorowych...")
    print("-" * 60)

    udane = 0
    for plik in pliki:
        sciezka_wejsciowa = os.path.join(FOLDER_ASSETS, plik)
        sciezka_wyjsciowa = os.path.join(folder_wyjsciowy, plik)

        try:
            napraw_strukture_svg(sciezka_wejsciowa, sciezka_wyjsciowa)
            print(f"[OK] Naprawiono: naprawione_svg/{plik}")
            udane += 1
        except Exception as err:
            print(f"[BLAD] Problem z plikiem {plik}: {err}")

    print("-" * 60)
    print(f"SUKCES! Naprawiono {udane} plików SVG pod silnik Godota.")

if __name__ == "__main__":
    try:
        main()
    except Exception as e:
        print(f"Błąd krytyczny: {e}")
        
    # Program poczeka na Enter i się nie zamknie
    input("\nPraca skończona. Wciśnij ENTER, aby zamknąć...")