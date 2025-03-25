import pandas as pd


def clean_csv(input_file, output_file):
    df = pd.read_csv(input_file)

    df.replace("N/A", None, inplace=True)
    df["Rank"] = pd.to_numeric(df["Rank"], errors="coerce").astype("Int64")
    sales_columns = ["NA_Sales", "EU_Sales", "JP_Sales", "Other_Sales", "Global_Sales"]
    for col in sales_columns:
        df[col] = pd.to_numeric(df[col], errors="coerce").astype(float)
    df["Year"] = pd.to_numeric(df["Year"], errors="coerce").astype("Int64")

    df.to_csv(output_file, index=False)
    print(f"Cleaned CSV saved as {output_file}")


if __name__ == "__main__":
    input_file = "vgsales.csv"
    output_file = "vgsales_cleaned.csv"
    clean_csv(input_file, output_file)
