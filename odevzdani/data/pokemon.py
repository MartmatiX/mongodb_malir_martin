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
    # Nacteni dat ze souboru
    read = pd.read_csv("pokemon.csv")

    basic_info(read)

    # Histogram celkoveho score
    plt.figure(figsize=(8, 5))
    sns.histplot(read['Total'], bins=20, kde=True, color='blue')
    plt.xlabel('Celkove Score')
    plt.ylabel('Pocet Pokemonu')
    plt.title('Distribuce celkoveho skore Pokemonu')
    plt.show()

    # Pocet pokemonu podle typu 1 - primarni
    plt.figure(figsize=(10, 5))
    sns.countplot(y=read['Type 1'], order=read['Type 1'].value_counts().index, hue=read['Type 1'], palette='viridis',
                  legend=False)
    plt.xlabel('Pocet Pokemonu')
    plt.ylabel('Typ 1')
    plt.title('Pocet Pokemonu podle primarniho typu')
    plt.show()

    # Korelace mezi statistikami
    plt.figure(figsize=(10, 6))
    sns.heatmap(read[['Total', 'HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed']].corr(), annot=True,
                cmap='coolwarm', fmt='.2f')
    plt.title('Korelacni matice statistik Pokemonu')
    plt.show()

    # Průměrné statistiky podle generace
    generation_stats = read.groupby('Generation').mean(numeric_only=True)
    generation_stats[['Total', 'HP', 'Attack', 'Defense', 'Sp. Atk', 'Sp. Def', 'Speed']].plot(kind='bar',
                                                                                               figsize=(12, 6))
    plt.title('Prumerne statistiky Pokemonu podle generace')
    plt.xlabel('Generace')
    plt.ylabel('Hodnota')
    plt.legend(loc='upper left')
    plt.show()
