import pandas as pd
import argparse
from tabulate import tabulate
import sys
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.abspath(os.path.join(BASE_DIR, ".."))

filepath = os.path.join(ROOT_DIR, "logs", "partition_log.jsonl")

def print_usage():
    print("""
Usage:
  flowdisk
  flowdisk --date YYYY-MM-DD
  flowdisk --time HH:MM:SS
  flowdisk --date YYYY-MM-DD --time HH:MM:SS
""")

class CustomParser(argparse.ArgumentParser):
    def error(self, message):
        print(f"\n {message}\n")
        print_usage()
        sys.exit(1)

parser = CustomParser()
parser.add_argument("--date")
parser.add_argument("--time")
args = parser.parse_args()


def validate_datetime(date, time):
    try:
        if date and time:
            return pd.to_datetime(f"{date} {time}")
        elif date:
            return pd.to_datetime(date)
        elif time:
            return time
        return None
    except:
        print("\n Invalid date/time format\n")
        print_usage()
        sys.exit(1)

filter_datetime = validate_datetime(args.date, args.time)


try:
    df = pd.read_json(filepath, lines=True, encoding="utf-16")
except ValueError:
    print("\nNo data found.\n")
    sys.exit(0)


if df.empty or "date" not in df.columns:
    print("\nNo data found.\n")
    sys.exit(0)


df["date"] = pd.to_datetime(df["date"], errors="coerce")


df = df.dropna(subset=["date"])

if df.empty:
    print("\nNo data found.\n")
    sys.exit(0)


if isinstance(filter_datetime, str):
    try:
        filter_datetime = pd.to_datetime(
            df["date"].dt.date.astype(str) + " " + filter_datetime
        ).min()
    except:
        print("\n Invalid time format\n")
        sys.exit(1)


if filter_datetime is not None:
    df = df[df["date"] > filter_datetime]
else:
    df = df.tail(50)

if df.empty:
    print("\nNo data found.\n")
    sys.exit(0)


if "Data" in df.columns:
    df = df.explode("Data").reset_index(drop=True)

    if df.empty:
        print("\nNo data found.\n")
        sys.exit(0)

    nested_df = pd.json_normalize(df["Data"])
    df = df.drop(columns=["Data"])
    df = pd.concat([df, nested_df], axis=1)


df["size_GB"] = pd.to_numeric(df["size_GB"], errors="coerce").round(2)
df = df.dropna(subset=["size_GB", "DriveLetter"])
df = df.sort_values(by="date")

if df.empty:
    print("\nNo data found.\n")
    sys.exit(0)


grouped = df.groupby("date")

rows = []
for date, group in grouped:
    drives = [
        f"{row['DriveLetter']} ({row['size_GB']} GB)"
        for _, row in group.iterrows()
    ]
    rows.append([date, ", ".join(drives)])

if not rows:
    print("\nNo data found.\n")
    sys.exit(0)


print(tabulate(rows, headers=["date", "Drives"], tablefmt="grid"))