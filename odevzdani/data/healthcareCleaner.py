import pandas as pd


def clean_csv(input_file, output_file):
    df = pd.read_csv(input_file)

    df["Date of Admission"] = pd.to_datetime(df["Date of Admission"], errors="coerce").dt.strftime('%Y-%m-%dT%H:%M:%SZ')
    df["Discharge Date"] = pd.to_datetime(df["Discharge Date"], errors="coerce").dt.strftime('%Y-%m-%dT%H:%M:%SZ')

    df.to_csv(output_file, index=False)


if __name__ == "__main__":
    input_file = "healthcare.csv"
    output_file = "healthcare_cleaned.csv"
    clean_csv(input_file, output_file)
