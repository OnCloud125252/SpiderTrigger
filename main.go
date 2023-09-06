package main

import (
	"encoding/json"
	"fmt"
	"github.com/acarl005/stripansi"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"os/exec"
	"strconv"
)

var port string = "8000"
var path string = "/auto-deploy"

type Payload struct {
	Repository struct {
		ID            int    `json:"id"`
		CloneURL      string `json:"clone_url"`
		DefaultBranch string `json:"default_branch"`
	} `json:"repository"`
}

func main() {
	http.HandleFunc(path, payloadHandler)

	fmt.Println("Server listening on port " + port + " ...")
	fmt.Println("Auto deploy path: " + path)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}

func payloadHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method == "POST" {
		body, err := ioutil.ReadAll(r.Body)
		if err != nil {
			http.Error(w, "Failed to read request body", http.StatusInternalServerError)
			return
		}
		defer r.Body.Close()

		var payload Payload
		err = json.Unmarshal(body, &payload)
		if err != nil {
			http.Error(w, "Failed to parse JSON body", http.StatusBadRequest)
			return
		}

		if payload.Repository.CloneURL == "" {
			http.Error(w, "Missing CloneURL in payload", http.StatusBadRequest)
			return
		}

		if payload.Repository.DefaultBranch == "" {
			http.Error(w, "Missing DefaultBranch in payload", http.StatusBadRequest)
			return
		}

		RepoURL := payload.Repository.CloneURL
		DefaultBranch := payload.Repository.DefaultBranch
		RepoID := strconv.Itoa(payload.Repository.ID)

		// Execute build process in a goroutine
		go func() {
			buildContainer := exec.Command("./builder.sh", "REPO_URL="+RepoURL, "DEFAULT_BRANCH="+DefaultBranch, "REPO_ID="+RepoID)

			logFile, buildContainerError := os.Create("./logs/log-" + RepoID + ".log")
			if buildContainerError != nil {
				panic(buildContainerError)
			}
			defer logFile.Close()

			buildContainer.Stdout = &cleanupWriter{writer: logFile}
			buildContainer.Stderr = &cleanupWriter{writer: logFile}
			buildContainerError = buildContainer.Start()
			buildContainer.Wait()

			if buildContainerError != nil {
				fmt.Println("Deployment failed for "+RepoID+": ", buildContainerError)
			} else {
				fmt.Println("Deployment for " + RepoID + " successful")
			}
		}()

		fmt.Fprint(w, "Deployment for "+RepoID+" started")
	} else {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}
}

// cleanupWriter is a custom writer that strips ANSI escape codes before writing to a file
type cleanupWriter struct {
	writer *os.File
}

// Write writes the cleaned output to the file
func (w *cleanupWriter) Write(p []byte) (n int, err error) {
	cleanOutput := stripansi.Strip(string(p))
	_, err = w.writer.WriteString(cleanOutput)
	return len(p), err
}
