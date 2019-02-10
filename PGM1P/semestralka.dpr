program sp;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  Crt,
  Classes;

const
  VYSLEDKY_FILE = 'vysledky.txt';
  SIRKA_DALNICE = 69;

// pro zapsani noveho vysledku do souboru
type vysledkovy_list = record
  body : integer;
  nick : String;
end;

// dva hraci
type hrac = record
  nick : String;
  x, y, tahu, vyher : Integer;
end;

// aby slo pole predat jako argument funkce
type
  TTwoDimCharArray = array of array of char;

type
  TSp = class
    procedure GetJmenaHracu;
    procedure GetVysledkyTurnaje;
    procedure GetCelkoveVysledky; 
    procedure GameRandom;
    procedure GameClassic;
    procedure Menu;
    procedure Odpocet;
    procedure Hra;
    procedure InicializujPromenne;
    procedure TestujKonecHry;
    procedure ExplainFile;
    procedure Napoveda;
    procedure ZapisVysledkyDoSouboru;

    var vyherce_nick : String;
    var vyherce_body, obtiznost_drahy, pocet_kol, rows, pocetJizdnichPruhu : Integer;
    var vysledky_txt : Text;
    var vysledkova_listina : array[0..10] of vysledkovy_list;
    var source_matrix, print_matrix: TTwoDimCharArray;
    var jizdniPruhy : array of integer; // cisla radek, kde jsou jizdni pruhy
    var help_array : array[0..SIRKA_DALNICE+1] of char;
    var hrac : array[1..2] of hrac;
  end;

  var Sp : TSp;

// prevede obtiznost na reverzni cislo
function reverzni(rev : integer) : integer;
begin
  result := 4 - rev;
end;

// zachvani der ve vozovce
function pole_do_matice(source_matrix, print_matrix: TTwoDimCharArray; help_array : array of char; I : integer) : integer;
var
  J : Integer;
begin
  // pomocne pole zapisu do print matice
  for J := 1 to SIRKA_DALNICE do
  begin
    if (help_array[J] = 'M') or (help_array[J] = 'K') or (help_array[J] = 'U') then
    begin
      print_matrix[I, J] := help_array[J];
    end
    else
    begin
    if source_matrix[I, J] = 'o' then
      print_matrix[I, J] := 'o'
    else
      print_matrix[I, J] := ' ';
    end;
  end;
  result := 1;
end;

// oznameni vyhry po skonceni jednoho kola
function vypisVyherceKola(x, rows, id_hrace: integer) : Integer;
var
  I, pom : integer;
begin
  pom := Trunc(rows / 2) - 1;
  Crt.GotoXY(x, pom);
  Crt.TextBackground(4);

  // horni okrasny radek
  for I := 0 to 27 do
    Write(#219);

  Crt.GotoXY(x, pom + 1);
  Write(#219, ' HRAC ', id_hrace, ' VYHRAL TOTO KOLO! ', #219);

  // dolni okrasny radek
  Crt.GotoXY(x, pom + 2);
  for I := 0 to 27 do
    Write(#219);

  Crt.Delay(3000);
  Crt.TextBackground(0);

  result := 1;
end;

// napoveda k ovladani hry
procedure TSp.Napoveda;
begin
  CRT.ClrScr;

  Writeln('Pro pohyb ve hre vyuzivate klaves:');
  Writeln('     Hrac 1          Hrac 2');
  Writeln('     +---+           +---+');
  Writeln('     | W |           | 8 |');
  Writeln(' +---+---+---+   +---+---+---+');
  Writeln(' | A |   | D |   + 4 |   | 6 |');
  Writeln(' +---+---+---+   +---+---+---+');

  Menu;
end;  

// rozparsuje dalnici a vytahu z ni potrebna data pro hru
procedure TSp.ExplainFile;
var
  str, fileName : String;
  chars, i, j, k : Integer;
begin
  fileName := Concat('dalnice_', IntToStr(obtiznost_drahy), '.txt');
  rows := 1;
  chars := 0;
  pocetJizdnichPruhu := -1; // prvni radek se nepocita

  if(FileExists(fileName)) then
  begin
    AssignFile(vysledky_txt, fileName);
    Reset(vysledky_txt);

    // v tomto pruchodu si zjistime velikost pole pro nacteni mapy
    while not eof(vysledky_txt) do
    begin
      Readln(vysledky_txt, str);

      if str[1] = ' ' then
        pocetJizdnichPruhu := pocetJizdnichPruhu + 1;
        
      chars := Length(str);
      rows := rows + 1;
    end;

    // nastavime velikosti poli
    SetLength(source_matrix, rows, chars);
    SetLength(print_matrix, rows, chars);
    SetLength(jizdniPruhy, pocetJizdnichPruhu);
    for i := 0 to pocetJizdnichPruhu do
    begin
      jizdniPruhy[i] := 5555;
    end;

    // nacteme soubor do pole (1 znak = 1 index)
    i := 1;
    Reset(vysledky_txt);
    while not eof(vysledky_txt) do
    begin
      Readln(vysledky_txt, str);

      // vybereme radky kde se smi generovat provoz
      if (str[1] = ' ') and (i <> 1) then
      begin
        for k := 0 to pocetJizdnichPruhu - 1 do
        begin
          if jizdniPruhy[k] = 5555 then
          begin
            jizdniPruhy[k] := i;
            break;
          end;
        end;
      end;

      // radku cteme po znacich a ty davame do souboru
      for j := 1 to chars do
      begin
        source_matrix[i, j] := str[j];
        print_matrix[i, j] := str[j];
      end;

      i := i + 1;
    end;
  end
  else
  begin
    Writeln('Chybi vstupni soubor s dalnici! Kontaktujte autora hry!!!');
    Readln;
    Halt(2);
  end;
end;

// inicializace klasicke hry
procedure TSp.GameClassic;
begin
  // obtiznost drahy
  repeat
    Write('Vyber obtiznost drahy <1;3>: ');

    try
      Readln(obtiznost_drahy);
    Except on E:Exception do end;
  until (obtiznost_drahy = 1) or (obtiznost_drahy = 2) or (obtiznost_drahy = 3);

  // vyber poctu kol
  repeat
    Write('vyber pocet kol <1;10>: ');

    try
      Readln(pocet_kol);
    Except on E:Exception do end;
  until (pocet_kol >= 1) and (pocet_kol <= 10);


  InicializujPromenne;
  Odpocet;
end;

// inicializace nahodne hry
procedure TSp.GameRandom;
begin
  Randomize;
  pocet_kol := Random(9) + 1;
  obtiznost_drahy := Random(2) + 1;

  InicializujPromenne;
  Odpocet;
end;

// nactu si jmena obou hracu pro pozdejsi ulozeni ve vysledkove listine
procedure TSp.GetJmenaHracu;
begin
  Writeln('Vitej ve hre dalnice...');

  repeat
    Write('Zadej nick hrace 1: ');
    Readln(hrac[1].nick);
  until (length(hrac[1].nick) >= 1);
  repeat
    Write('Zadej nick hrace 2: ');
    Readln(hrac[2].nick);
  until (length(hrac[2].nick) >= 1) and (hrac[1].nick <> hrac[2].nick);

  Crt.ClrScr;
  Writeln('Proti sobe se utkaji hraci: ', hrac[1].nick, ' a ', hrac[2].nick);
end;

// zobrazi vysledkovou listinu ze souboru
procedure TSp.GetCelkoveVysledky;
var
  str : String;
  i, j : integer;
begin
  CRT.ClrScr;
  Writeln('========== VYSLEDKOVA LISTINA ==========');
  Writeln('Body  Prezdivka');

  if(FileExists(VYSLEDKY_FILE)) then
  begin
    AssignFile(vysledky_txt, VYSLEDKY_FILE);
    Reset(vysledky_txt);

    while not eof(vysledky_txt) do
    begin
      Readln(vysledky_txt, str);

      // zarovnani
      for i := 1 to length(str) do
      begin
        Write(str[i]);
        if str[i] = ' ' then
        begin
          for j := 0 to 5-i do
            Write(' ');
        end;
      end;
      Writeln;
    end;
    closefile(vysledky_txt);
  end
  else
    Writeln('Vysledky nenalezeny!');

  Writeln('========== VYSLEDKOVA LISTINA ==========');
  Menu;
end;

// vysledky jenom tohoto turnaje
procedure TSp.GetVysledkyTurnaje;
var
  size, i, j, pom_tahu : Integer;
begin
  // ulozim si jmeno vyherce
  if (hrac[1].vyher > hrac[2].vyher) or ((hrac[1].vyher = hrac[2].vyher) and (hrac[1].tahu < hrac[2].tahu)) then
  begin
    vyherce_nick := hrac[1].nick;
    pom_tahu := hrac[1].tahu;
  end
  else if (hrac[1].vyher = hrac[2].vyher) and (hrac[1].tahu = hrac[2].tahu) then
  begin
    vyherce_nick := concat(hrac[1].nick, ', ', hrac[2].nick);
    pom_tahu := hrac[1].tahu;
  end
  else
  begin
    vyherce_nick := hrac[2].nick;
    pom_tahu := hrac[2].tahu;
  end;

  vyherce_body := reverzni(obtiznost_drahy) * pom_tahu;

  CRT.ClrScr;
  Writeln('=========== VYSLEDEK TURNAJE ===========');
  Writeln('Odehralo se ', pocet_kol, ' kol s obtiznosti ', obtiznost_drahy);
  Write('Celkovy vyherce tohoto turnaje je hrac: ');
  CRT.TextBackground(14);
  Write(vyherce_nick);
  CRT.TextBackground(0);
  Writeln;
  Writeln('Nickname          Tahu     Vyher');

  // vypis hrace vcetne zarovnani
  for i := 1 to 2 do
  begin
    Write(hrac[i].nick);
    size := 18 - length(hrac[i].nick);
    for j := 0 to size do
      write(' ');

    Write(hrac[i].tahu);
    size := 9 - length(IntToStr(hrac[i].tahu));
    for j := 0 to size do
      write(' ');

    Writeln(hrac[i].vyher);
  end;  

  Writeln('=========== VYSLEDEK TURNAJE ===========');

  ZapisVysledkyDoSouboru;
  Menu;
end;

// zapisu vysledky probehle hry do souboru
procedure TSp.ZapisVysledkyDoSouboru;
var
  pom1, pom2, str, ch : String;
  byla_mezera, i, j, k, kk, zapsano : Integer;
begin
  vyherce_nick := 'kokotakov777';
  vyherce_body := 20;
  zapsano := 0;

  if FileExists(VYSLEDKY_FILE) then
  begin
    // nactu si soucasne vysledky ze souboru
    AssignFile(vysledky_txt, VYSLEDKY_FILE);
    Reset(vysledky_txt);

    j := 0;
    while not eof(vysledky_txt) do
    begin
      Readln(vysledky_txt, str);

      pom1 := '';
      pom2 := '';
      byla_mezera := 0;

      // ctu po znacich a hledam mezeru
      for i := 1 to length(str) do
      begin
        if str[i] = ' ' then
        begin
          byla_mezera := 1;
          continue;
        end;

        if byla_mezera = 0 then
          pom1 := Concat(pom1, str[i])
        else
          pom2 := Concat(pom2, str[i]);
      end;

      vysledkova_listina[j].body := StrToInt(pom1);
      vysledkova_listina[j].nick := pom2;
      j := j + 1;
    end;
    closefile(vysledky_txt);

    // smazu soubor s vysledky
    Assign(vysledky_txt, VYSLEDKY_FILE);
    Erase(vysledky_txt);
  end;
  
  // zapisu do souboru (soucasti je vytvoreni souboru)
  AssignFile(vysledky_txt, VYSLEDKY_FILE);
  try
    Rewrite(vysledky_txt);

    kk := 0;
    for k := 0 to 10 do
    begin
      if ((vysledkova_listina[k].body = 0) and (zapsano <> 0)) or (kk = 10) then
        break;
        
      if (vyherce_body < vysledkova_listina[k].body) and (zapsano = 0) then
      begin
        ch := concat(IntToStr(vyherce_body), ' ', vyherce_nick);
        writeln(vysledky_txt, ch);
        zapsano := 1;
        kk := kk + 1;
      end;

      if (vysledkova_listina[k].body = 0) and (zapsano = 0) then
      begin
        ch := concat(IntToStr(vyherce_body), ' ', vyherce_nick);
        writeln(vysledky_txt, ch);
        break;
      end;

      ch := concat(IntToStr(vysledkova_listina[k].body), ' ', vysledkova_listina[k].nick);
      writeln(vysledky_txt, ch);
      kk := kk + 1;
    end;

    CloseFile(vysledky_txt);
  except
    // If there was an error the reason can be found here
    on E: EInOutError do
      writeln('File handling error occurred. Details: ', E.ClassName, '/', E.Message);
  end;

  GetCelkoveVysledky;
  CRT.Delay(2000);
end;

// Sprava herniho kola
procedure TSp.Hra;
var
  key, row : String;
  pom : char;
  I, J, h1xv, h2xv, h12yv: Integer;
begin
  // kontanty
  h1xv := 15;
  h2xv := 55;
  h12yv := rows - 1;

  // plneni promennych na zakladni hodnoty
  hrac[1].x := h1xv;
  hrac[2].x := h2xv;
  hrac[1].y := h12yv;
  hrac[2].y := h12yv;

  repeat
    // repaint a aktualizace herni mapy
    for I := 1 to (rows-1) do
    begin
      // aktualizace radky pokud v ni smi jezdit auta
      if source_matrix[I, 1] = ' ' then
      begin
        // vozidla na jednu stranu
        if i <= (rows/2) then
        begin
          // dam si posunuty radek do pomocneho pole
          for J := 1 to SIRKA_DALNICE do
          begin
            help_array[J + 1] := print_matrix[I, J];
          end;
          help_array[1] := help_array[SIRKA_DALNICE+1];

          // pomocne pole zapisu do print matice
          pole_do_matice(source_matrix, print_matrix, help_array, I);
        end
        else
        begin
          // vozidla na druhou stranu
          // dam si posunuty radek do pomocneho pole
          for J := SIRKA_DALNICE downto 1 do
          begin
            help_array[J - 1] := print_matrix[I, J];
          end;
          help_array[SIRKA_DALNICE] := help_array[1];

          // pomocne pole zapisu do print matice
          pole_do_matice(source_matrix, print_matrix, help_array, I);
        end;
      end;

      // repaint radky
      row := '';
      for J := 1 to SIRKA_DALNICE do
      begin
        row := Concat(row, print_matrix[I, J]);

        // testuji jestli nejake vozidlo nekoho zajede
        if (I = hrac[1].y) and ((print_matrix[I, hrac[1].x] = 'K') or (print_matrix[I, hrac[1].x] = 'M') or (print_matrix[I, hrac[1].x] = 'U')) then
        begin
          hrac[1].x := h1xv;
          hrac[1].y := h12yv;
        end;
        if (I = hrac[2].y) and ((print_matrix[I, hrac[2].x] = 'K') or (print_matrix[I, hrac[2].x] = 'M') or (print_matrix[I, hrac[2].x] = 'U')) then
        begin
          hrac[2].x := h2xv;
          hrac[2].y := h12yv;
        end;
      end;
      Writeln(row);
    end;

    // nekdo se hybe
    if CRT.KeyPressed then
    begin
      key := UpperCase(CRT.ReadKey());

      // hrac 1
      if(key = 'W') or (key = 'A') or (key = 'D') then
      begin
        // vpred
        if key = 'W' then
        begin
          pom := print_matrix[hrac[1].y - 1, hrac[1].x];
          if (hrac[1].y > 0) and (pom <> 'o') and (pom <> '#') and (pom <> '=') and (pom <> 'U') and (pom <> 'K') and (pom <> 'M') and not((hrac[1].y-1 = hrac[2].y) and (hrac[1].x = hrac[2].x)) then
          begin
            hrac[1].y := hrac[1].y - 1;
            hrac[1].tahu := hrac[1].tahu + 1;
          end;

          if hrac[1].y = 1 then
          begin
            hrac[1].vyher := hrac[1].vyher + 1;
            vypisVyherceKola(21, rows, 1);
            testujKonecHry;
          end;
        end;

        // doleva
        if key = 'A' then
        begin
          pom := print_matrix[hrac[1].y, hrac[1].x - 1];
          if (hrac[1].x > 1) and (pom <> 'o') and (pom <> '#') and (pom <> '=') and not((hrac[1].x-1 = hrac[2].x) and (hrac[1].y = hrac[2].y)) then
          begin
            hrac[1].x := hrac[1].x - 1;
            hrac[1].tahu := hrac[1].tahu + 1;
          end;
        end;

        // doprava
        if key = 'D' then
        begin
          pom := print_matrix[hrac[1].y, hrac[1].x + 1];
          if (hrac[1].x < SIRKA_DALNICE) and (pom <> 'o') and (pom <> '#') and (pom <> '=') and not((hrac[1].x+1 = hrac[2].x) and (hrac[1].y = hrac[2].y)) then
          begin
            hrac[1].x := hrac[1].x + 1;
            hrac[1].tahu := hrac[1].tahu + 1;
          end;
        end;
      end;

      // hrac 2
      if(key = '8') or (key = '4') or (key = '6') then
      begin
        // vpred
        if key = '8' then
        begin
          pom := print_matrix[hrac[2].y - 1, hrac[2].x];
          if (hrac[2].y > 0) and (pom <> 'o') and (pom <> '#') and (pom <> '=') and (pom <> 'U') and (pom <> 'K') and (pom <> 'M') and not((hrac[2].y-1 = hrac[1].y) and (hrac[2].x = hrac[1].x)) then
          begin
            hrac[2].y := hrac[2].y - 1;
            hrac[2].tahu := hrac[2].tahu + 1;
          end;

          if hrac[2].y = 1 then
          begin
            hrac[2].vyher := hrac[2].vyher + 1;
            vypisVyherceKola(21, rows, 2);
            testujKonecHry;
          end;
        end;

        // doleva
        if key = '4' then
        begin
          pom := print_matrix[hrac[2].y, hrac[2].x - 1];
          if (hrac[2].x > 1) and (pom <> 'o') and (pom <> '#') and (pom <> '=') and not((hrac[2].x-1 = hrac[1].x) and (hrac[1].y = hrac[2].y)) then
          begin
            hrac[2].x := hrac[2].x - 1;
            hrac[2].tahu := hrac[2].tahu + 1;
          end;
        end;

        // doprava
        if key = '6' then
        begin
          pom := print_matrix[hrac[2].y, hrac[2].x + 1];
          if (hrac[2].x < SIRKA_DALNICE) and (pom <> 'o') and (pom <> '#') and (pom <> '=') and not((hrac[2].x+1 = hrac[1].x) and (hrac[1].y = hrac[2].y)) then
          begin
            hrac[2].x := hrac[2].x + 1;
            hrac[2].tahu := hrac[2].tahu + 1;
          end;
        end;
      end;
    end;

    // vykresleni aktualni pozice kurzoru
    Crt.TextColor(14);
    Crt.GotoXY(hrac[1].x, hrac[1].y);
    Write('A');

    Crt.GotoXY(hrac[2].x, hrac[2].y);
    Write('B');
    Crt.TextColor(7);

    // pocet tahu
    Crt.GotoXY(1, rows);
    Writeln('======= STATISTIKY KOLA A HRY =======');
    Writeln('Prave se hraje kolo ', (hrac[1].vyher + hrac[2].vyher) , ' z ', pocet_kol , ' kol');
    Writeln('Pocet tahu hrace 1: ', hrac[1].tahu);
    Writeln('Pocet tahu hrace 2: ', hrac[2].tahu);
    Writeln('Celkovy stav: [', hrac[1].nick, ' vs. ', hrac[2].nick, '] ', hrac[1].vyher, ':', hrac[2].vyher);

    // 120
    CRT.Delay(180 - obtiznost_drahy * 30);
    CRT.ClrScr;
  until (false);
end;

// inicializace zakladnich promennych
procedure TSp.InicializujPromenne;
begin
  hrac[1].vyher := 0;
  hrac[2].vyher := 0;
  hrac[1].tahu := 0;
  hrac[2].tahu := 0;

  ExplainFile;
end;

// Menu programu
procedure TSp.Menu;
var
  volba : integer;
begin
  Writeln('================= MENU =================');
  Writeln('Prislusnou operaci zvolte danym cislem. ');
  Writeln('Zobrazit vysledkovou listinu ......... 1');
  Writeln('Hrat klasickou hru ................... 2');
  Writeln('Hrat nahodnou hru .................... 3');
  Writeln('Napoveda ovladani hry ................ 4');
  Writeln('Ukoncit program ...................... 5');
  Writeln('================= MENU =================');

  volba := 0;
  repeat
    Write('Zadejte vasi volbu: ');

    try
      Readln(volba);
    Except on E:Exception do end;
  until (volba >= 1) and (volba <= 5);

  // volani podprogramu
  case volba of
    1: GetCelkoveVysledky;
    2: GameClassic;
    3: GameRandom;
    4: Napoveda;
    else Halt(1);
  end;
end;

// Odpocet nekolika vterin pred zacatkem hry
procedure TSp.Odpocet;
var
  I : Integer;
begin
  CRT.ClrScr;
  //CRT.Delay(1000);

  for I := 1 downto 0 do
  begin
    Crt.TextBackground(I);
    
    if(I <> 0) then
      Writeln(I)
    else
      Writeln('GO!!!');

    CRT.Delay(750);
    CRT.ClrScr;
  end;

  Hra;
end;

// Test na ukonceni hry (dohrane vsechny kola)
procedure TSp.TestujKonecHry;
begin
  // budu pokracovat ve hre nebo ne?
  if (hrac[1].vyher + hrac[2].vyher) = pocet_kol then
  begin
    GetVysledkyTurnaje;
    Exit;
  end
  else
  begin
    Odpocet;
    Hra;
  end;
end;

// hlavni program
begin
  try
    Sp := TSp.Create;
    Sp.GetJmenaHracu;
    Sp.Menu;
    Readln; // aby se nevypnul program po ukonceni
    Sp.Free;
  except
    on E:Exception do
      Writeln(E.Classname, ': ', E.Message);
  end;
end.
