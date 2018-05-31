defmodule Learn.RestClient do
  alias Learn.{RestClient}
  import HTTPoison
  @version_endpoint  "/learn/api/public/v1/system/version"
  @oauth2_token_endpoint "/learn/api/public/v1/oauth2/token"
  @users_endpoint "/learn/api/public/v1/users"

  @enforce_keys [:fqdn, :key, :secret]
  defstruct [:fqdn, :key, :secret, :auth ]

  @doc """
    Create a new RestClient

    Returns %RestClient{fqdn: "fqdn", key: "key", secret: "secret"}

    ## Examples

    iex(1)> rc = Learn.RestClient.new("bd-partner-a-original.blackboard.com", "00000000-1111-2222-3333-444444444444", "12345678901234567890123456789012")
    %Learn.RestClient{
      fqdn: "bd-partner-a-original.blackboard.com",
      key: "00000000-1111-2222-3333-444444444444",
      secret: "12345678901234567890123456789012"
    }

  """
  def new(fqdn, key, secret) do
    %RestClient{fqdn: fqdn, key: key, secret: secret}
  end

  def new(fqdn, key, secret, auth) do
    %RestClient{fqdn: fqdn, key: key, secret: secret, auth: auth}
  end

  #Example use:
  # iex(5)> {code, response} = Learn.RestClient.get_learn_version(rc)

  def get_system_version(rest_client) do
    # GET /learn/api/public/v1/system/version
    url = "https://#{rest_client.fqdn}#{@version_endpoint}"
    {code, response} = HTTPoison.get url
  end

  def post_oauth2_token(rest_client, code, redirect_uri) do
    headers = [{"Content-Type",  "application/x-www-form-urlencoded"}]
    options = [hackney: [basic_auth: {"#{rest_client.key}", "#{rest_client.secret}"}] ]
    case code do
      0 ->
        url = "https://#{rest_client.fqdn}#{@oauth2_token_endpoint}"
        body = "grant_type=client_credentials"
      _ ->
        url = "https://#{rest_client.fqdn}#{@oauth2_token_endpoint}" <> "?code=#{code}&redirect_uri=#{redirect_uri}"
        body = "grant_type=authorization_code"
    end
    # IO.puts :stdio, "Calling HTTPoison.post"
    {code, respone} = HTTPoison.post url, body, headers, options
  end

  @doc """
    Convenience method to get and save the authorization. Returns a RestClient
    with the auth. If we call this with code other than 0, we're doing 3LO.
    We've previously gotten the code from logging in via the
    /learn/api/public/v1/oauth2/authorizationcode endpoint.
    Example:
    /learn/api/public/v1/oauth2/authorizationcode?redirect_uri=https://localhost&response_type=code&client_id=d128e50d-c91e-47d3-a97e-9d0c8a77fb5d&scope=read
  """
  def authorize(rest_client, code, redirect_uri) do
    case {code, response} = post_oauth2_token(rest_client, code, redirect_uri) do
      {:ok, response} -> {:ok, auth} = Poison.decode(response.body)
      {_, response } -> raise("rest_client: #{inspect rest_client} code: #{Atom.to_string(code)} response: #{inspect response}")
      _ -> raise("rest_client: #{inspect rest_client} code: #{Atom.to_string(code)} response: #{inspect response}")
    end
    case auth do
      %{"access_token" => _, "token_type" => _, "expires_in" => _ } -> auth
      _ -> raise("rest_client: #{inspect rest_client} auth: #{inspect auth}")
    end
    # With the return value we can do rest_client.auth["access_token"], or .auth["expires_in"]
    RestClient.new(rest_client.fqdn, rest_client.key, rest_client.secret, auth)
  end

  @doc """
    Convenience method to authroize using two-legged OAuth.
    We call authorize with a code of 0 to indicate two-legged.
    Of course there is no redirect_uri.
  """
  def authorize(rest_client) do
    authorize(rest_client, 0, "")
  end

  def get_user(rest_client, user_id) do
    url = "https://#{rest_client.fqdn}#{@users_endpoint}/#{user_id}"
    headers = [{"Content-Type",  "application/json"}, {"Authorization", "Bearer #{rest_client.auth["access_token"]}"}]
    options = []
    {code, response} = HTTPoison.get url, headers, options
  end

end
