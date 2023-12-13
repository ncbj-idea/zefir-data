from datetime import date

import pandas as pd
import requests

URL = "https://bdl.stat.gov.pl/api/v1/"
ID = "id"
NAME = "name"
VAR_ID = "var-id"
VALUE = "val"
VALUES = "values"
MEASURE_NAME = "measureUnitName"
YEAR = "year"
YEARS_LIST = [i for i in range(1995, date.today().year + 1)]
RESULTS = "results"
HEADERS = {
    "Host": "bdl.stat.gov.pl",
    "X-ClientId": "b3492776-4f80-42d1-a7b9-08da23b449ef",
}

territorial_unit_type = {
    None: "Powiat",
    "1": "Gmina miejska",
    "2": "Gmina wiejska",
    "3": "Gmina miejsko-wiejska",
    "4": "Miasto w gminie miejsko-wiejskiej",
    "5": "Obszar wiejski w gminie miejsko-wiejskiej",
    "8": "Dzielnice m. st. Warszawa",
    "9": "Delegatury i dzielnice innych gmin miejskich",
}
variables_name = {
    504: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        (
            "Energia elektryczna w gospodarstwach domowych w miastach (Wymiary:"
            " Elektroenergetyka)"
        ),
        "odbiorcy energii elektrycznej",
        "",
        "",
        "",
        "szt.",
    ],
    505: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        (
            "Energia elektryczna w gospodarstwach domowych w miastach (Wymiary:"
            " Elektroenergetyka)"
        ),
        "zużycie energii elektrycznej",
        "",
        "",
        "",
        "MWh",
    ],
    634118: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        (
            "Energia elektryczna w gospodarstwach domowych w miastach (Wymiary:"
            " Elektroenergetyka)"
        ),
        "zużycie energii elektrycznej na 1 mieszkańca",
        "",
        "",
        "",
        "kWh",
    ],
    1611895: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        (
            "Energia elektryczna w gospodarstwach domowych w miastach (Wymiary:"
            " Elektroenergetyka)"
        ),
        "zużycie energii elektrycznej na 1 odbiorcę",
        "",
        "",
        "",
        "kWh",
    ],
    79127: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        (
            "Korzystający z instalacji w % ogółu ludności (Wymiary: Lokalizacje;"
            " Rodzaje instalacji)"
        ),
        "ogółem",
        "gaz",
        "",
        "",
        "%",
    ],
    79128: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        (
            "Korzystający z instalacji w % ogółu ludności (Wymiary: Lokalizacje;"
            " Rodzaje instalacji)"
        ),
        "w miastach",
        "gaz",
        "",
        "",
        "%",
    ],
    6958: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        "Sieć gazowa (Wymiary: Sieć gazowa)",
        "odbiorcy gazu (gospodarstwa domowe)",
        "",
        "",
        "",
        "szt.",
    ],
    1620488: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        "Sieć gazowa (Wymiary: Sieć gazowa)",
        "odbiorcy gazu w mln",
        "",
        "",
        "",
        "gosp.",
    ],
    8519: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        "Sieć gazowa (Wymiary: Sieć gazowa)",
        "odbiorcy gazu (gospodarstwa domowe) ogrzewający mieszkania gazem",
        "",
        "",
        "",
        "szt.",
    ],
    60798: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        "Sieć gazowa (Wymiary: Sieć gazowa)",
        "odbiorcy gazu (gospodarstwa domowe) w miastach",
        "",
        "",
        "",
        "szt.",
    ],
    79173: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        (
            "Zużycie wody, energii elektrycznej oraz gazu w gospodarstwach domowych"
            " (Wymiary: Lokalizacje; Woda/energia elektryczna/gaz; Wskaźniki)"
        ),
        "w miastach",
        "energia elektryczna w miastach",
        "na 1 mieszkańca",
        "",
        "kWh",
    ],
    79182: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        (
            "Zużycie wody, energii elektrycznej oraz gazu w gospodarstwach domowych"
            " (Wymiary: Lokalizacje; Woda/energia elektryczna/gaz; Wskaźniki)"
        ),
        "w miastach",
        "energia elektryczna w miastach",
        "na 1 odbiorcę (gosp.dom.)",
        "",
        "kWh",
    ],
    196565: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "ZASOBY MIESZKANIOWE",
        "Budynki mieszkalne w gminie (Wymiary: Budynki mieszkalne)",
        "ogółem",
        "",
        "",
        "",
        "-",
    ],
    1612085: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "ZASOBY MIESZKANIOWE",
        (
            "Mieszkania wyposażone w instalacje - w % ogółu mieszkań (Wymiary:"
            " Lokalizacje; Rodzaje instalacji)"
        ),
        "ogółem",
        "gaz sieciowy",
        "",
        "",
        "%",
    ],
    199202: [
        "LUDNOŚĆ",
        "STAN LUDNOŚCI",
        (
            "Ludność w gminach bez miast na prawach powiatu i w miastach na prawach"
            " powiatu wg płci (Wymiary: Zakres terytorialny; Miejsce zamieszkania /"
            " zameldowania; Stan na dzień; Płeć)"
        ),
        "gminy bez miast na prawach powiatu",
        "miejsce zamieszkania",
        "stan na 30 czerwca",
        "ogółem",
        "osoba",
    ],
    453371: [
        "LUDNOŚĆ",
        "STAN LUDNOŚCI",
        (
            "Ludność wg funkcjonalnych grup wieku i płci w podziale na miasto i wieś"
            " (Wymiary: Funkcjonalne grupy wieku; Płeć; Lokalizacje)"
        ),
        "ogółem",
        "ogółem",
        "ogółem",
        "",
        "osoba",
    ],
    60572: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "ZASOBY MIESZKANIOWE",
        "Zasoby mieszkaniowe - wskaźniki (Wymiary: Wskaźniki)",
        "przeciętna powierzchnia użytkowa 1 mieszkania",
        "",
        "",
        "",
        "m2",
    ],
    60810: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "ZASOBY MIESZKANIOWE",
        "Zasoby mieszkaniowe (Wymiary: Lokalizacje; Zasoby mieszkaniowe wszystkie)",
        "ogółem",
        "powierzchnia użytkowa mieszkań",
        "",
        "",
        "m2",
    ],
    60811: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "ZASOBY MIESZKANIOWE",
        "Zasoby mieszkaniowe (Wymiary: Lokalizacje; Zasoby mieszkaniowe wszystkie)",
        "ogółem",
        "mieszkania",
        "",
        "",
        "-",
    ],
    475703: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "ZASOBY MIESZKANIOWE",
        "Zasoby mieszkaniowe - wskaźniki (Wymiary: Wskaźniki)",
        "przeciętna liczba osób na 1 mieszkanie",
        "",
        "",
        "",
        "-",
    ],
    474123: [
        "GOSPODARKA MIESZKANIOWA I KOMUNALNA",
        "URZĄDZENIA SIECIOWE",
        "Sieć gazowa (Wymiary: Sieć gazowa)",
        "zużycie gazu przez gospodarstwa domowe w MWh",
        "",
        "",
        "",
        "MWh",
    ],
    747066: [
        "PRZEMYSŁ I BUDOWNICTWO",
        "BUDOWNICTWO MIESZKANIOWE",
        "Budownictwo mieszkaniowe – wskaźniki (Wymiary: Wskaźniki)",
        "nowe budynki mieszkalne na 1000 ludności",
        "",
        "",
        "",
        "-",
    ],
    747060: [
        "PRZEMYSŁ I BUDOWNICTWO",
        "BUDOWNICTWO MIESZKANIOWE",
        "Budownictwo mieszkaniowe – wskaźniki (Wymiary: Wskaźniki)",
        "mieszkania oddane do użytkowania na 1000 ludności",
        "",
        "",
        "",
        "-",
    ],
    1638162: [
        "PRZEMYSŁ I BUDOWNICTWO",
        "BUDOWNICTWO MIESZKANIOWE",
        (
            "Budynki mieszkalne nowe oddane do użytkowania (dane kwartalne) (Wymiary:"
            " Okresy; Formy budownictwa; Rodzaje budynków; Technologie  wznoszenia)"
        ),
        "rok",
        "ogółem",
        "ogółem",
        "ogółem",
        "-",
    ],
    1638178: [
        "PRZEMYSŁ I BUDOWNICTWO",
        "BUDOWNICTWO MIESZKANIOWE",
        (
            "Budynki mieszkalne nowe oddane do użytkowania (dane kwartalne) (Wymiary:"
            " Okresy; Formy budownictwa; Rodzaje budynków; Technologie  wznoszenia)"
        ),
        "rok",
        "ogółem",
        "jednorodzinny",
        "ogółem",
        "-",
    ],
    1638194: [
        "PRZEMYSŁ I BUDOWNICTWO",
        "BUDOWNICTWO MIESZKANIOWE",
        (
            "Budynki mieszkalne nowe oddane do użytkowania (dane kwartalne) (Wymiary:"
            " Okresy; Formy budownictwa; Rodzaje budynków; Technologie  wznoszenia)"
        ),
        "rok",
        "ogółem",
        "wielorodzinny",
        "ogółem",
        "-",
    ],
    748243: [
        "PRZEMYSŁ I BUDOWNICTWO",
        "BUDOWNICTWO MIESZKANIOWE",
        (
            "Mieszkania oddane do użytkowania (dane kwartalne) (Wymiary: Okresy; Formy"
            " budownictwa; Wyszczególnienie; Zakres przedmiotowy)"
        ),
        "rok",
        "ogółem",
        "ogółem",
        "powierzchnia użytkowa mieszkań",
        "-",
    ],
    748244: [
        "PRZEMYSŁ I BUDOWNICTWO",
        "BUDOWNICTWO MIESZKANIOWE",
        (
            "Mieszkania oddane do użytkowania (dane kwartalne) (Wymiary: Okresy; Formy"
            " budownictwa; Wyszczególnienie; Zakres przedmiotowy)"
        ),
        "rok",
        "ogółem",
        "nowe budynki mieszkalne",
        "mieszkania",
        ""
    ],
    55421: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "przed 1918",
        "mieszkania",
        "",
        "",
        "-",
    ],
    55418: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "przed 1918",
        "powierzchnia użytkowa",
        "",
        "",
        "m2",
    ],
    55419: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "1918 - 1944",
        "mieszkania",
        "",
        "",
        "-",
    ],
    55416: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "1918 - 1944",
        "powierzchnia użytkowa",
        "",
        "",
        "m2",
    ],
    55413: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "1945 - 1970",
        "mieszkania",
        "",
        "",
        "-",
    ],
    55410: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "1945 - 1970",
        "powierzchnia użytkowa",
        "",
        "",
        "m2",
    ],
    55411: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "1971 - 1978",
        "mieszkania",
        "",
        "",
        "-",
    ],
    55409: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "1971 - 1978",
        "powierzchnia użytkowa",
        "",
        "",
        "m2",
    ],
    55415: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "1979 - 1988",
        "mieszkania",
        "",
        "",
        "-",
    ],
    55420: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "1979 - 1988",
        "powierzchnia użytkowa",
        "",
        "",
        "m2",
    ],
    55422: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "1989-2002 łącznie z będącymi w budowie",
        "mieszkania",
        "",
        "",
        "-",
    ],
    55417: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "1989-2002 łącznie z będącymi w budowie",
        "powierzchnia użytkowa",
        "",
        "",
        "m2",
    ],
    55412: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "2001 - 2002 łącznie z będącymi w budowie",
        "mieszkania",
        "",
        "",
        "-",
    ],
    55414: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg okresu budowy budynku (Wymiary: Okres budowy;"
            " Mieszkania / powierzchnia)"
        ),
        "2001 - 2002 łącznie z będącymi w budowie",
        "powierzchnia użytkowa",
        "",
        "",
        "m2",
    ],
    56027: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg powierzchni użytkowej (Wymiary: Rodzaje"
            " mieszkań; Powierzchnia)"
        ),
        "mieszkania ogółem",
        "ogółem",
        "",
        "",
        "-",
    ],
    55698: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg powierzchni użytkowej (Wymiary: Rodzaje"
            " mieszkań; Powierzchnia)"
        ),
        "mieszkania ogółem",
        "poniżej 30 m2",
        "",
        "",
        "-",
    ],
    55706: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg powierzchni użytkowej (Wymiary: Rodzaje"
            " mieszkań; Powierzchnia)"
        ),
        "mieszkania ogółem",
        "30 - 39 m2",
        "",
        "",
        "-",
    ],
    55703: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg powierzchni użytkowej (Wymiary: Rodzaje"
            " mieszkań; Powierzchnia)"
        ),
        "mieszkania ogółem",
        "40 - 49 m2",
        "",
        "",
        "-",
    ],
    55705: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg powierzchni użytkowej (Wymiary: Rodzaje"
            " mieszkań; Powierzchnia)"
        ),
        "mieszkania ogółem",
        "50 - 59 m2",
        "",
        "",
        "-",
    ],
    55710: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg powierzchni użytkowej (Wymiary: Rodzaje"
            " mieszkań; Powierzchnia)"
        ),
        "mieszkania ogółem",
        "60 - 79 m2",
        "",
        "",
        "-",
    ],
    55707: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg powierzchni użytkowej (Wymiary: Rodzaje"
            " mieszkań; Powierzchnia)"
        ),
        "mieszkania ogółem",
        "80 - 99 m2",
        "",
        "",
        "-",
    ],
    55697: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg powierzchni użytkowej (Wymiary: Rodzaje"
            " mieszkań; Powierzchnia)"
        ),
        "mieszkania ogółem",
        "100 - 119 m2",
        "",
        "",
        "-",
    ],
    55700: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg powierzchni użytkowej (Wymiary: Rodzaje"
            " mieszkań; Powierzchnia)"
        ),
        "mieszkania ogółem",
        "120 m2 i więcej",
        "",
        "",
        "-",
    ],
    55387: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg rodzaju podmiotów będących właścicielami"
            " mieszkań (Wymiary: Wyszczególnienie; Rodzaje własności)"
        ),
        "mieszkania ogółem",
        "ogółem",
        "",
        "",
        "-",
    ],
    55374: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg rodzaju podmiotów będących właścicielami"
            " mieszkań (Wymiary: Wyszczególnienie; Rodzaje własności)"
        ),
        "mieszkania ogółem",
        "osób fizycznych",
        "",
        "",
        "-",
    ],
    55378: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg rodzaju podmiotów będących właścicielami"
            " mieszkań (Wymiary: Wyszczególnienie; Rodzaje własności)"
        ),
        "mieszkania ogółem",
        "gminy",
        "",
        "",
        "-",
    ],
    55385: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg rodzaju podmiotów będących właścicielami"
            " mieszkań (Wymiary: Wyszczególnienie; Rodzaje własności)"
        ),
        "powierzchnia użytkowa mieszkania ogółem",
        "ogółem",
        "",
        "",
        "-",
    ],
    55381: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg rodzaju podmiotów będących właścicielami"
            " mieszkań (Wymiary: Wyszczególnienie; Rodzaje własności)"
        ),
        "powierzchnia użytkowa mieszkania ogółem",
        "osób fizycznych",
        "",
        "",
        "-",
    ],
    55379: [
        "NARODOWE SPISY POWSZECHNE",
        "NSP 2002 - MIESZKANIA ZAMIESZKANE",
        (
            "Mieszkania zamieszkane wg rodzaju podmiotów będących właścicielami"
            " mieszkań (Wymiary: Wyszczególnienie; Rodzaje własności)"
        ),
        "powierzchnia użytkowa mieszkania ogółem",
        "gminy",
        "",
        "",
        "-",
    ],
}

params = {
    "var-id": [id for id in variables_name.keys()],
    "format": "json",
    "year": [i for i in range(1995, date.today().year + 1)],
    "page-size": 100,
}


def get_measures():
    measures = {}
    data = requests.get(f"{URL}measures?", headers=HEADERS, params={"lang": "pl"})
    for measure in data.json()[RESULTS]:
        measures.setdefault(measure[ID], measure[NAME])
    return measures


def for_one_territorial_unit():
    all_object_request = requests.get(
        f"{URL}subjects", headers=HEADERS, params={"lang": "pl"}
    )
    all_object_dict = {
        item[NAME]: item[ID] for item in all_object_request.json()[RESULTS]
    }
    # all_object_dict contains subjects with K-type ID  e.g. K15, K43 etc.
    print(all_object_dict)

    all_sub_object_request = requests.get(
        f"{URL}subjects",
        headers=HEADERS,
        params={"parent-id": all_object_dict[input().upper().strip()]},
    )
    all_sub_object_dict = {
        item[NAME]: item[ID] for item in all_sub_object_request.json()[RESULTS]
    }
    # all_sub_object_dict contains subjects with G-type ID  e.g. G59, G562 etc.
    print(all_sub_object_dict)

    all_topics_request = requests.get(
        f"{URL}subjects",
        headers=HEADERS,
        params={"parent-id": all_sub_object_dict[input().upper().strip()]},
    )
    all_topics_dict = {
        item[NAME]: item[ID] for item in all_topics_request.json()[RESULTS]
    }
    # all_topics_dict contains subjects with G-type ID  e.g. P2955, P2496 etc.
    print(all_topics_dict)

    all_sub_topics_request = requests.get(
        f"{URL}variables",
        headers=HEADERS,
        params={"subject-id": all_topics_dict[input().capitalize().strip()]},
    )
    all_sub_topics_dict = {
        item["n2"] + "-" + item["n1"]: item[ID]
        for item in all_sub_topics_request.json()["results"]
    }
    print(all_sub_topics_dict)

    request_data = requests.get(
        f"{URL}data/by-unit/{TERYT}",
        headers=HEADERS,
        params={"var-id": input("ID: "), "year": YEARS_LIST},
    )
    return request_data


def unit_search():
    city = input("Enter the city: ").capitalize()
    query_params = {"name": city, "page-size": "100", "format": "json", "lang": "pl"}

    data = requests.get(
        f"{URL}/units/search?", headers=HEADERS, params=query_params
    ).json()
    unit_data = {
        i[ID]: [i[NAME], territorial_unit_type.setdefault(i["kind"])]
        for i in data[RESULTS]
    }
    for id in unit_data.keys():
        temp_data = requests.get(f"{URL}/units/{id}", headers=HEADERS).json()["years"]
        unit_data.setdefault(id).append(temp_data)

    if len(unit_data) > 1:
        for unit_id, unit_info in unit_data.items():
            if len(unit_info[2]) > 5:
                print(
                    f"{unit_info[0]} - {unit_id}, {unit_info[1]},"
                    f" [{min(unit_info[2])}-{max(unit_info[2])}]"
                )
            else:
                print(f"{unit_info[0]} - {unit_id}, {unit_info[1]}, {unit_info[2]}")
        city_id = input("Select the city id: ")
        return city_id, unit_data.get(city_id)[0]
    else:
        for unit_id, unit_info in unit_data.items():
            return unit_id, unit_info[0]


def get_data():
    data = requests.get(
        f"{URL}/data/by-unit/{TERYT}", headers=HEADERS, params=params
    ).json()

    data_frames_list = []

    for item in data[RESULTS]:
        test = {}
        for subject in item[VALUES]:
            test.setdefault(
                subject[YEAR], {tuple(variables_name.get(item[ID])): subject[VALUE]}
            )
        data_frames_list.append(pd.DataFrame(test))
    assert data["totalRecords"] > 0, "No data found for selected TERYT"
    a = pd.concat(data_frames_list)

    a.to_excel(file_name, merge_cells=False)
    print(f"The data was successfully saved to file {file_name}")


temp_value = unit_search()
TERYT = temp_value[0]
file_name = f"{temp_value[1]}_data.xlsx"

get_data()
