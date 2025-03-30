import matplotlib.pyplot as plt
import pandas as pd
import seaborn as sns


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
    read = pd.read_csv("vgsales_cleaned.csv")

    basic_info(read)

    # Pocet her podle platformy
    plt.figure(figsize=(10, 5))
    sns.countplot(y=read['Platform'], order=read['Platform'].value_counts().index, palette='viridis')
    plt.xlabel('Pocet her')
    plt.ylabel('Platforma')
    plt.title('Pocet her podle platformy')
    plt.show()

    # Korelace mezi prodeji
    plt.figure(figsize=(10, 6))
    sns.heatmap(read[['NA_Sales', 'EU_Sales', 'JP_Sales', 'Other_Sales', 'Global_Sales']].corr(), annot=True,
                cmap='coolwarm', fmt='.2f')
    plt.title('Korelacni matice prodeju videoher')
    plt.show()

    # Prodeje podle zanru
    genre_sales = read.groupby('Genre').mean(numeric_only=True)
    genre_sales['Global_Sales'].sort_values().plot(kind='barh', figsize=(10, 6), color='skyblue')
    plt.xlabel('Prumerna celosvetova prodejnost v milionech')
    plt.ylabel('Zanr')
    plt.title('Prumerna celosvetova prodejnost')
    plt.show()
