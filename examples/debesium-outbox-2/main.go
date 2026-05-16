package main

import (
	"context"
	"crypto/rand"
	"flag"
	"fmt"
	"log"
	"math/big"
	"os"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
)

var count int

func main() {
	flag.IntVar(&count, "count", 0, "how many random records needed?")
	flag.Parse()

	ctx := context.Background()
	fmt.Printf("Generating %d random records\n", count)

	conn, err := pgx.Connect(context.Background(), "postgres://tibobit:tibobit@localhost:5432/orderdb")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Unable to connect to database: %v\n", err)
		os.Exit(1)
	}

	defer func() {
		_ = conn.Close(ctx)
	}()

	for range count {
		tx, err := conn.Begin(ctx)
		if err != nil {
			log.Println("failed to start tx: ", err.Error())

			return
		}

		orderID := uuid.New()
		amount, _ := rand.Int(rand.Reader, big.NewInt(100000))
		payload := fmt.Sprintf(
			`{"id": "%s", "amount": "%s", "base": "usdt", "quote": "btc"}`,
			orderID.String(),
			amount.String(),
		)

		fmt.Println(payload)

		_, err = tx.Exec(context.Background(), `INSERT INTO outbox_schema.outbox (id, aggregatetype, aggregateid, type, payload)
VALUES (
    gen_random_uuid(),
    'order-aggregate',
    $1,
    'OrderCreated',
    $2::jsonb
);`, orderID, payload)
		if err != nil {
			fmt.Fprintf(os.Stderr, "QueryRow failed: %v\n", err)
			_ = tx.Rollback(ctx)

			os.Exit(1)
		}

		_ = tx.Commit(ctx)

	}
}
