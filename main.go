package main

import (
	"context"
	"encoding/json"
	"fmt"

	"github.com/alecthomas/kong"
	"github.com/apache/arrow-adbc/go/adbc"
	"github.com/apache/arrow-adbc/go/adbc/drivermgr"
	"github.com/rs/zerolog/log"
)

var (
	version    = "development"
	driver     = "lib/osx-universal/libduckdb.dylib"
	extensions = "extensions"

	cli struct {
		Version kong.VersionFlag `help:"Print the version and exit" short:"v"`
		Debug   bool             `help:"Enable debug logging."`
	}
)

func main() {
	kong.Parse(&cli,
		kong.Description("Packaging tool which builds Lambda deployment archives from a list of binaries."),
		kong.Vars{
			"version": version,
		},
	)

	var drv drivermgr.Driver
	db, err := drv.NewDatabase(map[string]string{
		"driver":     driver,
		"entrypoint": "duckdb_adbc_init",
	})
	if err != nil {
		log.Fatal().Err(err).Msg("failed to open database")
	}

	ctx := context.Background()

	cnxn, err := db.Open(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to open connection")
	}

	defer cnxn.Close()

	err = executeQuery(cnxn, fmt.Sprintf("SET custom_extension_repository = '%s';", extensions))
	if err != nil {
		log.Fatal().Err(err).Msg("failed to execute custom extension repository")
	}

	err = executeQuery(cnxn, "INSTALL httpfs;")
	if err != nil {
		log.Fatal().Err(err).Msg("failed to execute install of httpfs")
	}

	// you can use cnxn to query the duckdb instance

	st, err := cnxn.NewStatement()
	if err != nil {
		log.Fatal().Err(err).Msg("failed to create statement")
	}

	defer st.Close()

	err = st.SetSqlQuery(`SELECT * FROM "data/iceberg/lineitem_iceberg/data/00041-414-f3c73457-bbd6-4b92-9c15-17b241171b16-00001.parquet"`)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to set query")
	}

	rdr, _, err := st.ExecuteQuery(ctx)
	if err != nil {
		log.Fatal().Err(err).Msg("failed to execute query")
	}
	defer rdr.Release()

	log.Info().Msg("query executed")

	for rdr.Next() {
		rec := rdr.Record()

		data, err := json.Marshal(rec)
		if err != nil {
			log.Fatal().Err(err).Msg("failed to marshal record")
		}

		fmt.Println(string(data))

		rec.Release()
	}
}

func executeQuery(cnxn adbc.Connection, sql string) error {
	st, err := cnxn.NewStatement()
	if err != nil {
		return err
	}

	defer st.Close()

	err = st.SetSqlQuery(sql)
	if err != nil {
		return err
	}

	_, _, err = st.ExecuteQuery(context.Background())
	if err != nil {
		return err
	}

	return nil
}
