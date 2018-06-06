defmodule Learn.RestClient do
  alias Learn.{RestClient}
  import HTTPoison
  # oauth
  @v1_oauth2_token "/learn/api/public/v1/oauth2/token"
  @v1_oauth2_authorization_code "/learn/api/public/v1/oauth2/authorizationcode"

  @v1_system_version  "/learn/api/public/v1/system/version"

  @v1_users "/learn/api/public/v1/users"

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

    iex(3)> rc = Learn.RestClient.new("bd-partner-a-original.blackboard.com", System.get_env("APP_KEY"), System.get_env("APP_SECRET"))
%Learn.RestClient{
  auth: nil,
  fqdn: "bd-partner-a-original.blackboard.com",
  key: "d128e50d-c91e-47d3-a97e-9d0c8a77fb5d",
  secret: "xyzzy"
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
    url = "https://#{rest_client.fqdn}#{@v1_system_version}"
    {code, response} = HTTPoison.get url
  end

  def post_oauth2_token(rest_client, code, redirect_uri) do
    headers = [{"Content-Type",  "application/x-www-form-urlencoded"}]
    options = [hackney: [basic_auth: {"#{rest_client.key}", "#{rest_client.secret}"}] ]
    case code do
      0 ->
        url = "https://#{rest_client.fqdn}#{@v1_oauth2_token}"
        body = "grant_type=client_credentials"
      _ ->
        url = "https://#{rest_client.fqdn}#{@v1_oauth2_token}" <> "?code=#{code}&redirect_uri=#{redirect_uri}"
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
    https://bd-partner-a-original.blackboard.com/learn/api/public/v1/oauth2/authorizationcode?redirect_uri=https://localhost&response_type=code&client_id=d128e50d-c91e-47d3-a97e-9d0c8a77fb5d&scope=read%20offline
    Browser is then redirected to Learn login page. We login with mkauffman-student3 and browser is sent to:
    https://localhost/?code=oDNloDmgqEFbPoSRCYjKKskQMBIYjWp6

    iex(4)> rcauth = Learn.RestClient.authorize(rc, "oDNloDmgqEFbPoSRCYjKKskQMBIYjWp6", "https://localhost")
%Learn.RestClient{
  auth: %{
    "access_token" => "qm1vVtvjR05Zs405YIvzOwGY2aJQ809f",
    "expires_in" => 3599,
    "scope" => "read",
    "token_type" => "bearer",
    "user_id" => "02f8aa8b159c4bd3a54a35bb29bc1f8c"
  },
  fqdn: "bd-partner-a-original.blackboard.com",
  key: "d128e50d-c91e-47d3-a97e-9d0c8a77fb5d",
  secret: "xyzzy"
}

  """
  def authorize(rest_client, code, redirect_uri) do
    case {code, response} = post_oauth2_token(rest_client, code, redirect_uri) do
      {:ok, response} -> {:ok, auth} = Poison.decode(response.body)
      {_, response } -> raise("rest_client: #{inspect rest_client} code: #{Atom.to_string(code)} response: #{inspect response}")
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
    url = "https://#{rest_client.fqdn}#{@v1_users}/#{user_id}"
    headers = [{"Content-Type",  "application/json"}, {"Authorization", "Bearer #{rest_client.auth["access_token"]}"}]
    options = []
    {code, response} = HTTPoison.get url, headers, options
  end

  def get_users_courses(rest_client, user_id) do
    url = "https://#{rest_client.fqdn}#{@v1_users}/#{user_id}/courses"
    headers = [{"Content-Type",  "application/json"}, {"Authorization", "Bearer #{rest_client.auth["access_token"]}"}]
    options = []
    {code, response} = HTTPoison.get url, headers, options
  end

end
