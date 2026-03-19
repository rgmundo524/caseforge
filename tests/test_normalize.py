from __future__ import annotations

import json
import shutil
import tempfile
import unittest
from pathlib import Path

from caseforge.build import build_db
from caseforge.intake import add_files
from caseforge.normalize import normalize_db


DUCKDB_BIN = shutil.which("duckdb")


class NormalizeTests(unittest.TestCase):
    def setUp(self) -> None:
        if DUCKDB_BIN is None:
            self.skipTest("duckdb binary not available")
        self.tmpdir = tempfile.TemporaryDirectory()
        self.root = Path(self.tmpdir.name)
        (self.root / "package.json").write_text("{}\n", encoding="utf-8")
        (self.root / "pages").mkdir()
        (self.root / "data" / "raw").mkdir(parents=True)

    def tearDown(self) -> None:
        self.tmpdir.cleanup()

    def _write_csv(self, name: str, text: str) -> Path:
        p = self.root / name
        p.write_text(text.strip() + "\n", encoding="utf-8")
        return p

    def _query_csv(self, sql: str) -> str:
        out = shutil.which("duckdb")
        import subprocess

        result = subprocess.run(
            [out, str(self.root / "data" / "case.duckdb"), "-csv", "-c", sql],
            text=True,
            check=True,
            capture_output=True,
        )
        return result.stdout.strip()

    def test_trm_account_normalization(self) -> None:
        trm = self._write_csv(
            "trm_account.csv",
            """
Type,Chain,Address,Entity URN,Name,Risk Score,Categories,Notes,Txn Hash,Timestamp,From,To,Asset,Value,Value USD
address,ethereum,0xA,urn:a,Alpha,5,Exchange,,, ,,,,
address,ethereum,0xB,urn:b,Beta,3,Service,,, ,,,,
transfer,ethereum,,,,,label-1,hash1,2025-01-01 00:00:00,0xA,0xB,ETH,1.5,3000
            """,
        )
        add_files(case_root=self.root, files=[trm], source_system="trm", tx_model="account")
        normalize_db(case_root=self.root, duckdb_bin=DUCKDB_BIN)
        out = self._query_csv("select vendor,tx_model,tx,source_label,destination_label,value,usd from normalized_combined_transactions")
        self.assertIn("trm,account,hash1,Alpha,Beta,1.5,3000.0", out)

    def test_trm_utxo_dedup_value(self) -> None:
        trm = self._write_csv(
            "trm_utxo.csv",
            """
Type,Chain,Address,Entity URN,Name,Risk Score,Categories,Notes,Txn Hash,Timestamp,From,To,Asset,Value,Value USD
address,bitcoin,addr1,urn:a,Label1,5,Cat,,, ,,,,
address,bitcoin,addr2,urn:b,Label2,2,Cat,,, ,,,,
transfer,bitcoin,,,,,utxo-note,tx-1,2025-01-01 00:00:00,addr1,addr2,BTC,2,200
transfer,bitcoin,,,,,utxo-note,tx-1,2025-01-01 00:00:00,addr1,addr2,BTC,2,200
            """,
        )
        add_files(case_root=self.root, files=[trm], source_system="trm", tx_model="utxo")
        normalize_db(case_root=self.root, duckdb_bin=DUCKDB_BIN)
        out = self._query_csv("select tx,value,usd,destination_address from normalized_combined_transactions")
        self.assertIn("tx-1,2.0,200.0,addr2", out)

    def test_qlue_account_normalization(self) -> None:
        qlue = self._write_csv(
            "qlue_account.csv",
            """
Transfer Type,Block,Time,Transfer Label,Transaction,Source Address Label,Source Address Hash,Source Group,Source Group Description,Recipient Address Label,Recipient Address Hash,Recipient Group,Recipient Group Description,Crypto Value,Crypto Asset,USD,CAD,JPY,EUR,Index,Address Entities,Address Flags
x,1,2025-01-01 00:00:00,lbl,tx1,slabel,saddr,sg,sgd,dlabel,daddr,dg,dgd,10,USDT,10,,,,0,,
            """,
        )
        add_files(case_root=self.root, files=[qlue], source_system="qlue", export_type="account", blockchain="ethereum")
        normalize_db(case_root=self.root, duckdb_bin=DUCKDB_BIN)
        out = self._query_csv("select vendor,tx_model,blockchain,asset,value from normalized_combined_transactions")
        self.assertIn("qlue,account,ethereum,USDT,10.0", out)

    def test_qlue_utxo_in_out_assignment(self) -> None:
        qlue = self._write_csv(
            "qlue_utxo.csv",
            """
Block,Time,Transaction Label,Transaction Hash,Number of I/O,Address Label,Address Hash,Address Flags,Address Entities,Crypto Value,Token Policy,USD,CAD,JPY,EUR,Direction,Source Group,Source Group Description,Recipient Group,Recipient Group Description
1,2025-01-01 00:00:00,label,txh,1,srcLabel,srcAddr,,,1.0 BTC,BTC,10,,,,in,SG,SGD,,
1,2025-01-01 00:00:01,label,txh,1,dstLabel,dstAddr,,,1.0 BTC,BTC,10,,,,out,,,RG,RGD
            """,
        )
        add_files(case_root=self.root, files=[qlue], source_system="qlue", export_type="utxo", blockchain="bitcoin")
        normalize_db(case_root=self.root, duckdb_bin=DUCKDB_BIN)
        out = self._query_csv("select source_address,destination_address,destination_group from normalized_combined_transactions")
        self.assertIn("srcAddr,dstAddr,RG", out)

    def test_header_validation_failure(self) -> None:
        bad = self._write_csv("bad.csv", "A,B\n1,2")
        add_files(case_root=self.root, files=[bad], source_system="trm", tx_model="account")
        with self.assertRaises(RuntimeError):
            normalize_db(case_root=self.root, duckdb_bin=DUCKDB_BIN)

    def test_normalize_then_build(self) -> None:
        qlue = self._write_csv(
            "qlue_account.csv",
            """
Transfer Type,Block,Time,Transfer Label,Transaction,Source Address Label,Source Address Hash,Source Group,Source Group Description,Recipient Address Label,Recipient Address Hash,Recipient Group,Recipient Group Description,Crypto Value,Crypto Asset,USD,CAD,JPY,EUR,Index,Address Entities,Address Flags
x,1,2025-01-01 00:00:00,lab,tx1,slabel,saddr,sg,sgd,dlabel,daddr,dg,dgd,10,ETH,100,,,,0,,
            """,
        )
        add_files(case_root=self.root, files=[qlue], source_system="qlue", export_type="account", blockchain="ethereum")
        normalize_db(case_root=self.root, duckdb_bin=DUCKDB_BIN)
        build_db(case_root=self.root, duckdb_bin=DUCKDB_BIN)
        out = self._query_csv("select count(*) as c from transactions")
        self.assertIn("1", out)


if __name__ == "__main__":
    unittest.main()
