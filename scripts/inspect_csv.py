from pathlib import Path
import pandas as pd

RAW_DIR = Path("data/raw")


def main():
    files = sorted(RAW_DIR.glob("*.csv"))
    if not files:
        print("Aucun CSV trouvé dans", RAW_DIR.resolve())
        return

    for f in files:
        df = pd.read_csv(f)
        print("=" * 60)
        print(f.name)
        print("lignes:", len(df), "| colonnes:", df.shape[1])
        print(df.dtypes)
        missing = df.isna().sum()
        print("valeurs manquantes:")
        print(missing[missing > 0] if (missing > 0).any() else "aucune")
        print("lignes entièrement dupliquées:", df.duplicated().sum())


if __name__ == "__main__":
    main()