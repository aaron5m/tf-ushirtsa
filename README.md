## Printful Serverless Storefront

A high-performance, serverless e-commerce store built with **Terraform** and **AWS Lambda**.

### Architecture
* **Frontend:** CloudFront-distributed SPA.
* **Payment Lambda:** Handles Stripe Payment Intents (Live Mode) and CORS.
* **Order Lambda:** Securely automates Printful API order creation.
* **CI/CD:** GitHub Actions with automated Node.js dependency injection.

### Highlights
* **Infrastructure as Code:** Fully automated AWS provisioning.
* **Secure:** Environment-driven secret management and cross-Lambda communication.
* **Scalable:** 100% serverless architecture with zero fixed costs.

---

This is a simple showcase of a working e-commerce store provisioned with terraform and AWS. Secrets are managed with github secrets or locally. Every git push re-applies terraform.

The site sends up the payment intent from the stripe API to an AWS "payment" lambda, which confirms the payment and passes the order off to an AWS "order" lambda, which passes the order through the printful API to printful. All told, fairly simple.

But sound enough for one who with what wit  
and will should seek therefrom to build upon.

You can buy a shirt and see it work for $20.26.

[ushirtsa.com](https://ushirtsa.com)

