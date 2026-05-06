# finpay-otelcol-proto

`finpay-otelcol` の gRPC API 定義（`.proto`）とコード生成を管理するリポジトリです。
このリポは --Go module としてタグ公開--し、`finpay-otelcol-app` から `go get ...@vX.Y.Z` で参照される前提です。

- Source of truth: `proto/` 配下の `.proto`
- Tooling: `buf`（lint / format / generate / breaking）
- Generated code: `gen/go/...`（--生成物はコミットする--方針）

> 生成物をコミットすることで、利用側（app）は `buf/protoc` なしで `go get` するだけで使えます。
> その代わり、`.proto` 変更時は必ず `make generate` → 生成物コミットが必要です。

---

## Repository layout

```bash
finpay-otelcol-proto/
├─ proto/
│ └─ finpay/v1/finpay.proto
├─ gen/
│ └─ go/ ... (generated)
├─ buf.yaml
├─ buf.gen.yaml
├─ Makefile
└─ go.mod
```

---

## Quickstart

## Usage (最小例)


```Go
package main

import (
	"context"
	"log"
	"time"

	pb "github.com/shtsukada/finpay-otelcol-proto/gen/go/finpay/v1"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

func main() {
	conn, err := grpc.Dial(
		"localhost:50051",
		grpc.WithTransportCredentials(insecure.NewCredentials()),
	)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	client := pb.NewFinpayServiceClient(conn)

	ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
	defer cancel()

	resp, err := client.CreateTransfer(ctx, &pb.CreateTransferRequest{
		FromAccountId: "acct-1",
		ToAccountId:   "acct-2",
		Amount: &pb.Money{
			Currency: "JPY",
			Amount:   1000,
		},
	})
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("transfer_id=%s status=%s", resp.TransferId, resp.Status)
}

```

### Prerequisites

- `buf`（推奨：バージョン固定。例：`buf --version` をREADME/CIで確認）
- Go（`go.mod` に準拠）

### Commands

#### Lint / Format

```bash
make lint
make format
```

#### Generate (Go)

```bash
make generate
```

## Versioning policy

このリポジトリの公開バージョンはSemVer(`vMAJOR.MINOR.PATCH`)で管理します。
- MAJOR
  - 既存利用者に影響する破壊的変更を含む場合
- MINOR
  - 後方互換を保った機能追加
  - 例:新しい message / rpc / field の追加
- PATCH
  - 後方互換に影響しない修正
  - 例:コメント修正、README修正、精製物更新のみ、整形のみ
このリポジトリを参照する`finpay-otelcol-app` では、 `go get ...@vX.Y.Z` のように明示的なタグで依存を固定します。

## Backward compatibility

このリポジトリでは `.proto` の変更に対して後方互換性を原則として維持します。
互換性の破壊は `buf breaking` で検知し、CIでも必須チェックとします。

### 基本ルール

- fieldの番号は 再利用しない
- 削除する場合は reserved を使う
- 削除した field 名も必要に応じて reserved にする
- enum 値も同様に reserved で管理する
- 既存利用者に影響する変更は breaking change として扱う

## Reserved policy

`reserved` は、過去に使っていたfield番号や名前を再利用しないための宣言です。
これにより、将来の変更で古いクライアントとの衝突や誤解釈を防ぎます。

### 使う場面

- fieldを削除した時
- field名を廃止した時
- enum valueを削除した時

例
```proto
message CreateTransferRequest {
  reserved 3;
  reserved "legacy_note";
}
```

### 運用ルール

- 削除だけして終わりにしない
- 「使わなくなった番号・名前」は再利用せずreservedに残す
- reservedの追加自体は、互換性維持のための対応として扱う

## What is treated as a breaking change

このリポジトリでは、例えば次のような変更をbreaking changeとして扱います。
- 既存の service / rpc / message / field を削除する
- 既存の field の番号を変更する
- 既存fieldの方を互換性なく変更する
- enum value を互換性なく変更・削除する
- パッケージや公開APIの参照パスに影響する変更を行う

迷った場合は、既存の`finpay-otelcol-app`がそのまま更新なしで取り込めるかを基準に判断します。
そのまま取り込めない可能性があるならbreaking changeとみなします。

## Procedure for introducing a breaking change

breaking changeを入れる場合は、次の流れで進めます。
1. その変更が本当にbreakingか判断する
  - 既存利用者に影響するか
  - 代替としてfield追加で吸収できないか
2. 必要なら`reserved`を追加する
  - 削除した番号・名前・enum valueを保護する
3. `.proto`を修正する
4. Lint / format / generate / breaking check を通す
```bash
make lint
make format
make generate
make breaking
```
5. 生成物の差分をコミットする
6. PRを作成し、CIをgreenにする
7. mainにマージ後、MAJOR version を上げてtagを切る
8. `finpay-otelcol-app`側で依存versionを更新する
  - `go get ...@v2.0.0`
  - 必要なコード修正もapp側で行う

breaking change は、README・PR・tagの3点でわかる状態にします。

### CI policy

このリポの PR では少なくとも以下を保証します。

- buf lint
- buf format（差分が出る場合はPRで修正）
- buf breaking（後方互換性の保証）
- make generate の結果がコミット済み（git diff --exit-code で検査）

### Release / tagging policy

- Tags are SemVer: vMAJOR.MINOR.PATCH
- Breaking changes → MAJOR を上げる
- 新規フィールド追加等（後方互換） → MINOR
- コメント/整形/生成系の変更 → PATCH

推奨の流れ：

1. main にマージ
2. v0.1.0 のようにタグを切る
3. finpay-otelcol-app 側で go get ...@v0.1.0 に固定する

### Development checklist (when editing proto)

1. .proto を編集
2. make lint format
3. make generate（生成物を更新してコミット）
4. make breaking
5. PR 作成 → CI green

## License

MIT
