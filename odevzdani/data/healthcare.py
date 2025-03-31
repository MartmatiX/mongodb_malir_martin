import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


# Ziskani zakladnich informaci o datasetu
def basic_info(in_file):
    print("Zakladni informace:")
    print(in_file.info())
    print("\nPrvnich 5 radku:")
    print(in_file.head())
    print("\nStatisticke shrnuti:")
    print(in_file.describe())
    print("\nPocet chybejicich hodnot:")
    print(in_file.isnull().sum())


if __name__ == "__main__":
    read = pd.read_json("healthcare_cleaned.json")

    basic_info(read)

    read["Date of Admission"] = pd.to_datetime(read["Date of Admission"])
    read["Discharge Date"] = pd.to_datetime(read["Discharge Date"])

    read["Hospital Stay"] = (read["Discharge Date"] - read["Date of Admission"]).dt.days

    plt.figure(figsize=(8, 5))
    sns.histplot(read["Billing Amount"], bins=20, kde=True, color='blue')
    plt.xlabel("Fakturovana castka")
    plt.ylabel("Pocet pacientu")
    plt.title("Distribuce fakturovanych castek")
    plt.show()

    plt.figure(figsize=(10, 5))
    sns.countplot(y=read["Admission Type"], order=read["Admission Type"].value_counts().index, palette='viridis')
    plt.xlabel("Pocet pacientu")
    plt.ylabel("Typ prijmu")
    plt.title("Pocet pacientu podle typu prijmu")
    plt.show()

    plt.figure(figsize=(8, 5))
    read.groupby("Admission Type")["Hospital Stay"].mean().sort_values().plot(kind="bar", color="purple")
    plt.xlabel("Typ prijmu")
    plt.ylabel("Prumerna delka hospitalizace - dny")
    plt.title("Prumerna delka hospitalizace podle typu prijmu")
    plt.show()
