package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/mail"
	"os"
	"strings"
	"unicode"
	"unicode/utf8"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/ses"
	"github.com/aws/aws-sdk-go-v2/service/ses/types"
)

type ContactRequest struct {
	Name    string `json:"name"`
	Email   string `json:"email"`
	Message string `json:"message"`
}

const (
	maxContactRequestBytes  = 20 * 1024
	maxContactNameLength    = 100
	maxContactEmailLength   = 254
	maxContactMessageLength = 4000
)

var sesClient *ses.Client

func init() {
	cfg, _ := config.LoadDefaultConfig(context.TODO(), config.WithRegion("eu-west-1"))
	sesClient = ses.NewFromConfig(cfg)
}

func handler(ctx context.Context, request events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error) {
	headers := map[string]string{
		"Access-Control-Allow-Origin":  "*",
		"Access-Control-Allow-Methods": "POST, OPTIONS",
		"Access-Control-Allow-Headers": "Content-Type",
	}

	if request.RequestContext.HTTP.Method == "OPTIONS" {
		return events.LambdaFunctionURLResponse{StatusCode: 200, Headers: headers}, nil
	}

	if request.RequestContext.HTTP.Method != "POST" {
		headers["Allow"] = "POST, OPTIONS"
		return events.LambdaFunctionURLResponse{StatusCode: 405, Headers: headers, Body: "Method not allowed"}, nil
	}

	req, err := parseContactRequest(request.Body)
	if err != nil {
		return events.LambdaFunctionURLResponse{StatusCode: 400, Headers: headers, Body: "Invalid request"}, nil
	}

	sender := os.Getenv("SENDER_EMAIL")

	input := &ses.SendEmailInput{
		Destination: &types.Destination{
			ToAddresses: []string{sender},
		},
		ReplyToAddresses: []string{req.Email},
		Message: &types.Message{
			Subject: &types.Content{
				Data: aws.String(fmt.Sprintf("[Portfolio] Nuevo mensaje de %s", req.Name)),
			},
			Body: &types.Body{
				Text: &types.Content{
					Data: aws.String(fmt.Sprintf("Remitente: %s\nEmail: %s\n\nMensaje:\n%s", req.Name, req.Email, req.Message)),
				},
			},
		},
		Source: aws.String(sender),
	}

	_, err = sesClient.SendEmail(ctx, input)
	if err != nil {
		fmt.Printf("Error enviando email con SES: %v\n", err)
		return events.LambdaFunctionURLResponse{StatusCode: 500, Body: "Error sending email", Headers: headers}, nil
	}

	return events.LambdaFunctionURLResponse{
		StatusCode: 200,
		Headers:    headers,
		Body:       "Message sent successfully!",
	}, nil
}

func parseContactRequest(body string) (ContactRequest, error) {
	var req ContactRequest
	if len(body) > maxContactRequestBytes {
		return req, errors.New("request body too large")
	}
	if err := json.Unmarshal([]byte(body), &req); err != nil {
		return req, errors.New("invalid JSON")
	}

	req.Name = strings.TrimSpace(req.Name)
	req.Email = strings.TrimSpace(req.Email)
	req.Message = strings.TrimSpace(req.Message)

	if req.Name == "" || utf8.RuneCountInString(req.Name) > maxContactNameLength || hasControlCharacters(req.Name, false) {
		return ContactRequest{}, errors.New("invalid name")
	}
	if len(req.Email) > maxContactEmailLength || hasControlCharacters(req.Email, false) {
		return ContactRequest{}, errors.New("invalid email")
	}
	address, err := mail.ParseAddress(req.Email)
	if err != nil || address.Address != req.Email {
		return ContactRequest{}, errors.New("invalid email")
	}
	if req.Message == "" || utf8.RuneCountInString(req.Message) > maxContactMessageLength || hasControlCharacters(req.Message, true) {
		return ContactRequest{}, errors.New("invalid message")
	}

	return req, nil
}

func hasControlCharacters(value string, allowWhitespace bool) bool {
	for _, character := range value {
		if unicode.IsControl(character) && !(allowWhitespace && (character == '\n' || character == '\r' || character == '\t')) {
			return true
		}
	}
	return false
}

func main() {
	lambda.Start(handler)
}
