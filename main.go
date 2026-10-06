package main

import (
	"log"
	"net/http"
	"os"

	"go.elastic.co/apm/module/apmhttp/v2"
	"go.elastic.co/apm/v2"
)

func main() {
	mux := http.NewServeMux()
	mux.HandleFunc("/healthz", func(w http.ResponseWriter, _ *http.Request) { w.WriteHeader(http.StatusOK) })
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		span, _ := apm.StartSpan(r.Context(), "work", "app.internal")
		defer span.End()
		w.Write([]byte("ok\n"))
	})

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Config comes entirely from ELASTIC_APM_* env vars; healthz is excluded via ELASTIC_APM_TRANSACTION_IGNORE_URLS.
	handler := apmhttp.Wrap(mux)
	log.Printf("listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, handler))
}
