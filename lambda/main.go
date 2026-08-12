package main

import (
	"context"
	"encoding/json"
	"fmt"
	"os"

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

var sesClient *ses.Client

func init() {
	cfg, _ := config.LoadDefaultConfig(context.TODO(), config.WithRegion("eu-west-1"))
	sesClient = ses.NewFromConfig(cfg)
}

func handler(ctx context.Context, request events.APIGatewayProxyRequest) (events.APIGatewayProxyResponse, error) {
	headers := map[string]string{
		"Access-Control-Allow-Origin":  "*",
		"Access-Control-Allow-Methods": "POST, OPTIONS",
		"Access-Control-Allow-Headers": "Content-Type",
	}

	if request.HTTPMethod == "OPTIONS" {
		return events.APIGatewayProxyResponse{StatusCode: 200, Headers: headers}, nil
	}

	var req ContactRequest
	if err := json.Unmarshal([]byte(request.Body), &req); err != nil {
		return events.APIGatewayProxyResponse{StatusCode: 400, Body: "Invalid request"}, nil
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

	_, err := sesClient.SendEmail(ctx, input)
	if err != nil {
		fmt.Printf("Error enviando email con SES: %v\n", err)
		return events.APIGatewayProxyResponse{StatusCode: 500, Body: "Error sending email", Headers: headers}, nil
	}

	return events.APIGatewayProxyResponse{
		StatusCode: 200,
		Headers:    headers,
		Body:       "Message sent successfully!",
	}, nil
}

func main() {
	lambda.Start(handler)
}
