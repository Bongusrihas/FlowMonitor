import pandas as pd
import argparse
from tabulate import tabulate
import sys
import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
ROOT_DIR = os.path.abspath(os.path.join(BASE_DIR, ".."))
filepath = os.path.join(ROOT_DIR, "logs", "domains_log.csv")



def print_usage():
    print("""
Usage:
  flowdomain
  flowdomain 20
  flowdomain --date YYYY-MM-DD
  flowdomain --time HH:MM:SS
  flowdomain --date YYYY-MM-DD --time HH:MM:SS
""")


class CustomParser(argparse.ArgumentParser):
    def error(self, message):
        print(f"\n{message}\n")
        print_usage()
        sys.exit(1)


parser = CustomParser()
parser.add_argument("count", nargs="?", type=int, help="Show last N entries")
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
        print("\nInvalid date/time format\n")
        print_usage()
        sys.exit(1)


filter_datetime = validate_datetime(args.date, args.time)


try:
    df = pd.read_csv(filepath, names=["Time", "Domain"])
except Exception:
    print("\nNo data found.\n")
    sys.exit(0)

if df.empty:
    print("\nNo data found.\n")
    sys.exit(0)

df["Time"] = pd.to_datetime(
    df["Time"],
    format="%Y-%m-%d %H:%M:%S",  
    errors="coerce"
)

df = df.dropna(subset=["Time"])

df["Domain"] = df["Domain"].astype(str)
df = df.dropna(subset=["Domain"])

if df.empty:
    print("\nNo data found.\n")
    sys.exit(0)

if isinstance(filter_datetime, str):
    try:
        filter_datetime = pd.to_datetime(
            df["Time"].dt.date.astype(str) + " " + filter_datetime
        ).min()
    except:
        print("\nInvalid time format\n")
        sys.exit(1)


if filter_datetime is not None:
    df = df[df["Time"] > filter_datetime]
elif args.count:
    df = df.tail(args.count)
else:
    df = df.tail(50)


if df.empty:
    print("\nNo data found.\n")
    sys.exit(0)

df = df.drop_duplicates()

df = df.sort_values(by="Time", ascending=False)

print(tabulate(df, headers="keys", tablefmt="grid", showindex=False))