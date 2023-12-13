from  heat_density import calculate_connectivities
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use("QtAgg")
case = 2
#################################################3
#               USE CASE 1
#################################################3
if case==1:
    h3Sizes = [7,8,9]

    df = pd.read_excel("Data/ceeb_joined_bdot_sample.xlsx")
    #Filter buildings
    id = df.loc[:,"is_valid"] & df.loc[:,"czy_ogrzewany"]
    df = df.loc[ id,:]
    #Start
    hc = calculate_connectivities(df) #tworzymy obiekt
    h3Sizes = [7,8,9] #Definiujemy skalę H3 jaką chcemy używać
    dfH3 = hc.genH3(h3Size=h3Sizes)
    hc.run_calculations(h3Size=h3Sizes) #Puszczamy obliczenia z daną skalą. To mogę być te same skale dla których wygenerowano wyniki w poprzednim punkcie
    #Rysujemy wykresy
    hc.hist('heat_density')
    hc.hist('heat_distance')
    hc.hist('log_heat_connectivity')
    #Pokazujemy mape - działa w JupiterNotebook
    #hc.show_on_map(7)
    #Odczytujemy wyniki tj. w df3 mamy kolumnę z wygenerowaną kolumną heat_connectivity_index który ma 4 wartości
    df3 = hc.get_connectivity(h3Size=9)

#################################################3
#               USE CASE 1
#################################################3
if case==2:
    h3Sizes = [7,8,9]

    input = "ceeb_joined_bdot_sample"
    df = pd.read_excel(f"Data/{input}.xlsx")
    #Filter buildings
    id = df.loc[:,"is_valid"] & df.loc[:,"czy_ogrzewany"]
    df = df.loc[ id,:]
    #Start
    #Tworzymy dane i generujemy H3 + zapisujemy dane z H3, po to by potem nie musieć na nowo generować h3 - robimy to raz
    hc = calculate_connectivities(df) #tworzymy obiekt
    h3Sizes = [7,8,9] #Definiujemy skalę H3 jaką chcemy używać
    dfH3 = hc.genH3(h3Size=h3Sizes)
    dfH3.to_csv(f"Data/{input}_h3.csv",index=False)

    #Następnym razem już tylko czytamy dane z kolumnami H3
    dfH3=pd.read_csv(f"Data/{input}_h3.csv")
    hc = calculate_connectivities(dfH3) #Wrzucamy dane do modelu
    hc.run_calculations(h3Size=h3Sizes) #Puszczamy obliczenia z daną skalą. To mogę być te same skale dla których wygenerowano wyniki w poprzednim punkcie
    #Rysujemy wykresy
    hc.hist('heat_density')
    hc.hist('heat_distance')
    hc.hist('log_heat_connectivity')
    #Pokazujemy mape - działa w JupiterNotebook
    #hc.show_on_map(7)
    #Odczytujemy wyniki tj. w df3 mamy kolumnę z wygenerowaną kolumną heat_connectivity_index który ma 4 wartości
    df3 = hc.get_connectivity(h3Size=9, bins=4)
    plt.figure()
    plt.hist(df3['heat_connectivity_index'],bins=4)
    plt.show()
