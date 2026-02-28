# finpay-otelcol-proto

`finpay-otelcol` の gRPC API 定義（`.proto`）とコード生成を管理するリポジトリです。  
このリポは **Go module としてタグ公開**し、`finpay-otelcol-app` から `go get ...@vX.Y.Z` で参照される前提です。

- Source of truth: `proto/` 配下の `.proto`
- Tooling: `buf`（lint / format / generate / breaking）
- Generated code: `gen/go/...`（**生成物はコミットする**方針）

> ⚠️ 生成物をコミットすることで、利用側（app）は `buf/protoc` なしで `go get` するだけで使えます。  
> その代わり、`.proto` 変更時は必ず `make generate` → 生成物コミットが必要です。

---

## Repository layout

finpay-otelcol-proto/
├─ proto/
│ └─ finpay/v1/finpay.proto
├─ gen/
│ └─ go/ ... (generated)
├─ buf.yaml
├─ buf.gen.yaml
├─ Makefile
└─ go.mod

---

## Quickstart

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

API / contract notes (important)

1) Backward compatibility

- フィールド番号は 再利用しない
- 削除する場合は reserved を使う
- enum 値も同様に reserved で管理する
- breaking は buf breaking で検知する（CIで必須）

1) Error model is defined in app (gRPC status)

- このリポは API 形（messages/services）を提供します。
- Unauthenticated / FailedPrecondition / AlreadyExists / Unavailable 等の ステータス運用は app 側の契約です（設計は root の DESIGN.md を参照）。

1) High-cardinality fields

- transfer_id / idempotency_key 等は Observability 上の high-cardinality になり得ます。
- Prometheusラベルにはしない運用は app 側で守ります（このリポはフィールド定義のみ）。

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
