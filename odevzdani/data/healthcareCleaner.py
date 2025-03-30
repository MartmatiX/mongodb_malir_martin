import pandas as pd


def clean_csv_to_json(input_file, output_file):
    df = pd.read_csv(input_file)

    # Convert dates to proper datetime format
    df["Date of Admission"] = pd.to_datetime(df["Date of Admission"], errors="coerce")
    df["Discharge Date"] = pd.to_datetime(df["Discharge Date"], errors="coerce")

    # Convert DataFrame to JSON
    df.to_json(output_file, orient="records", date_format="iso")


if __name__ == "__main__":
    input_file = "healthcare.csv"
    output_file = "healthcare_cleaned.json"
    clean_csv_to_json(input_file, output_file)
