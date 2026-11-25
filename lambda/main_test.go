package main

import (
	"context"
	"encoding/json"
	"strings"
	"testing"

	"github.com/aws/aws-lambda-go/events"
)

func TestParseContactRequest(t *testing.T) {
	valid := ContactRequest{
		Name:    "  Ada Lovelace  ",
		Email:   "  ada@example.com  ",
		Message: "  Hello!\nI would like to connect.  ",
	}
	body, err := json.Marshal(valid)
	if err != nil {
		t.Fatal(err)
	}

	parsed, err := parseContactRequest(string(body))
	if err != nil {
		t.Fatalf("parseContactRequest() error = %v", err)
	}
	if parsed.Name != "Ada Lovelace" || parsed.Email != "ada@example.com" || parsed.Message != "Hello!\nI would like to connect." {
		t.Fatalf("parseContactRequest() = %#v, want trimmed fields", parsed)
	}
}

func TestParseContactRequestRejectsInvalidInput(t *testing.T) {
	tests := map[string]string{
		"invalid JSON":      "{",
		"empty fields":      `{"name":" ","email":"ada@example.com","message":"hello"}`,
		"invalid email":     `{"name":"Ada","email":"not-an-email","message":"hello"}`,
		"oversized name":    `{"name":"` + strings.Repeat("a", maxContactNameLength+1) + `","email":"ada@example.com","message":"hello"}`,
		"oversized message": `{"name":"Ada","email":"ada@example.com","message":"` + strings.Repeat("a", maxContactMessageLength+1) + `"}`,
		"control in name":   "{\"name\":\"Ada\\nB\",\"email\":\"ada@example.com\",\"message\":\"hello\"}",
		"oversized body":    strings.Repeat(" ", maxContactRequestBytes+1),
	}

	for name, body := range tests {
		t.Run(name, func(t *testing.T) {
			if _, err := parseContactRequest(body); err == nil {
				t.Fatal("parseContactRequest() succeeded, want an error")
			}
		})
	}
}

func TestHandlerRejectsNonPostMethods(t *testing.T) {
	var request events.LambdaFunctionURLRequest
	if err := json.Unmarshal([]byte(`{"version":"2.0","requestContext":{"http":{"method":"GET"}}}`), &request); err != nil {
		t.Fatal(err)
	}

	response, err := handler(context.Background(), request)
	if err != nil {
		t.Fatal(err)
	}
	if response.StatusCode != 405 {
		t.Fatalf("handler() status = %d, want 405", response.StatusCode)
	}
}
