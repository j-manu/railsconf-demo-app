class CurrenciesController < ApplicationController
  def history
    base_currency = params[:base_currency] || "USD"
    @currency_map = {
      "USD" => "United States Dollar",
      "EUR" => "Euro",
      "JPY" => "Japanese Yen",
      "GBP" => "British Pound Sterling",
      "AUD" => "Australian Dollar",
      "CAD" => "Canadian Dollar",
      "INR" => "Indian Rupee",
      "CHF" => "Swiss Franc",
      "CNY" => "Chinese Yuan"
    }

    uri = URI("https://api.currencyapi.com/v3/latest")
    uri.query = URI.encode_www_form({
      "base_currency" => base_currency,
      "currencies" => (@currency_map.keys - [ base_currency ]).join(",")
    })

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.get(uri, "apikey" => ENV.fetch("CURRENCY_API_KEY"))
    end

    @data = JSON.parse(response.body)["data"]
  end
end
