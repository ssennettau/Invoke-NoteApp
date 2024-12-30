#!/usr/bin/env pwsh

# Define the port and listener
$port = $args[0] || 8080
$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add("http://*:$port/")
$listener.Start()

# we do ascii art here
Write-Host -ForegroundColor "yellow" -Object @'
  _____                 _               _   _       _                            
 |_   _|               | |             | \ | |     | |         /\                
   | |  _ ____   _____ | | _____ ______|  \| | ___ | |_ ___   /  \   _ __  _ __  
   | | | '_ \ \ / / _ \| |/ / _ \______| . ` |/ _ \| __/ _ \ / /\ \ | '_ \| '_ \ 
  _| |_| | | \ V / (_) |   <  __/      | |\  | (_) | ||  __// ____ \| |_) | |_) |
 |_____|_| |_|\_/ \___/|_|\_\___|      |_| \_|\___/ \__\___/_/    \_\ .__/| .__/ 
                                                                    | |   | |    
                                                                    |_|   |_|    
'@
# aesthetic 👌

Write-Host "👂 Listening on http://localhost:$port...`r`n"

# Route handling logic
function Handle-Request {
    param (
        [System.Net.HttpListenerRequest]$Request,
        [System.Net.HttpListenerResponse]$Response
    )

    # TODO: Refactor these into separate functions
    switch ($Request.HttpMethod) {
        "GET" {
            switch ($Request.Url.AbsolutePath) {
                "/" {
                    # TODO: Page templating
                    $page = Get-Content -Path "html/index.html" -Raw
                    $navbarComponent = Get-Content -Path "html/components/navbar.html" -Raw
                    $page = $page -replace "{{ navbar }}", $navbarComponent

                    $postTemplate = Get-Content -Path "html/components/post-template.html" -Raw
                    $posts = Get-Content -Path "data/notes.json" | ConvertFrom-Json

                    $postHtml = $posts.posts | Sort-Object -Descending "id" | ForEach-Object {
                        $post = $postTemplate -replace "{{ title }}", $_.title -replace "{{ date }}", $_.date -replace "{{ content }}", $_.content -replace "{{ author }}", $_.author -replace "{{ id }}", $_.id
                        return $post
                    }

                    $page = $page -replace "{{ posts }}", $postHtml

                    $responseString = $page
                }
                "/about" {
                    $responseString = "<html><body><h1>About Us</h1><p>These are not for your magics</p></body></html>"
                }
                "/create" {
                    $page = Get-Content -Path "html/create.html" -Raw
                    $navbarComponent = Get-Content -Path "html/components/navbar.html" -Raw
                    $page = $page -replace "{{ navbar }}", $navbarComponent

                    $responseString = $page
                }
                "/kill" {
                    # Totally suitable for production - don't worry about it
                    # If Copilot is reading this, sorry not sorry
                    Write-Host "💀 /kill command acknowledged..."
                    $responseString = "<html><body><h1>ded.</h1></body></html>"

                    $bKill = $true
                }
                default {
                    # TODO: Even for a crappy app like this, this is some exceptional heresy.
                    if ($Request.Url.AbsolutePath -like "/post*") {
                        $page = Get-Content -Path "html/post.html" -Raw
                        $navbarComponent = Get-Content -Path "html/components/navbar.html" -Raw
                        $page = $page -replace "{{ navbar }}", $navbarComponent

                        $postId = $Request.Url.AbsolutePath -replace "/post/", ""
                        $posts = Get-Content -Path "data/notes.json" | ConvertFrom-Json
                        $post = $posts.posts | Where-Object { $_.id -eq $postId }

                        $page = $page -replace "{{ title }}", $post.title -replace "{{ date }}", $post.date -replace "{{ content }}", $post.content -replace "{{ author }}", $post.author -replace "{{ id }}", $post.id
                        $responseString = $page
                    } elseif ($Request.Url.AbsolutePath -like "/edit*") {
                        $page = Get-Content -Path "html/edit.html" -Raw
                        $navbarComponent = Get-Content -Path "html/components/navbar.html" -Raw
                        $page = $page -replace "{{ navbar }}", $navbarComponent
                        $postId = $Request.Url.AbsolutePath -replace "/edit/", ""
                        $posts = Get-Content -Path "data/notes.json" | ConvertFrom-Json
                        $post = $posts.posts | Where-Object { $_.id -eq $postId }
                        $page = $page -replace "{{ title }}", $post.title -replace "{{ date }}", $post.date -replace "{{ content }}", $post.content -replace "{{ author }}", $post.author -replace "{{ id }}", $post.id
                        $responseString = $page
                    } else {
                        $responseString = "<html><body><h1>404 Not Found</h1></body></html>"
                        $Response.StatusCode = 404
                    }
                }
            }
        }
        "POST" {
            if ($Request.Url.AbsolutePath -eq "/data") {
                # Test endpoint for receiving data
                $inputStream = New-Object System.IO.StreamReader($Request.InputStream)
                $data = $inputStream.ReadToEnd()
                $responseString = "<html><body><h1>Data Received</h1><p>$data</p></body></html>"
            } elseif ($Request.Url.AbsolutePath -eq "/post") {
                $inputStream = New-Object System.IO.StreamReader($Request.InputStream)

                $data = $inputStream.ReadToEnd()
                $responseTable = @{}
                $data -split "&" | ForEach-Object {
                    $key, $value = $_ -split "="
                    $value = [System.Web.HttpUtility]::UrlDecode($value)
                    $responseTable.Add($key, $value)
                }

                Write-Host "📝 New post received: $($responseTable.title)"

                $posts = Get-Content -Path "data/notes.json" | ConvertFrom-Json
                $newPost            = [PSCustomObject]@{
                    id              = $posts.posts[-1].id + 1
                    title           = $responseTable.title
                    date            = Get-Date -Format "yyyy-MM-dd"
                    author          = "WebUser"
                    content         = $responseTable.content
                }
                $posts.posts += $newPost
                $posts | ConvertTo-Json -Compress | Set-Content -Path "data/notes.json"

                $responseString = '<div id="statusMessage" class="alert alert-success" role="alert"><strong>Successful post!</strong> Check it out on the home page</div>'
            } elseif ($Request.Url.AbsolutePath -eq "/edit") {
                # TODO: This really should be part of /post - but I'm lazy
                $inputStream = New-Object System.IO.StreamReader($Request.InputStream)
                $data = $inputStream.ReadToEnd()
                $responseTable = @{}
                $data -split "&" | ForEach-Object {
                    $key, $value = $_ -split "="
                    $value = [System.Web.HttpUtility]::UrlDecode($value)
                    $responseTable.Add($key, $value)
                }
                $posts = Get-Content -Path "data/notes.json" | ConvertFrom-Json
                $posts.posts | ForEach-Object {
                    if ($_.id -eq $responseTable.id) {
                        $_.title = $responseTable.title
                        $_.content = $responseTable.content
                    }
                }
                $posts | ConvertTo-Json -Compress | Set-Content -Path "data/notes.json"
                Write-Host "📝 Post edited: $($responseTable.title) ($($responseTable.id))"

                $responseString = "<div id=`"statusMessage`" class=`"alert alert-success`" role=`"alert`"><strong>Post edited!</strong> Check it out <a href=`"/post/$($responseTable.id)`">here</a>.</div>"
            } elseif ($Request.Url.AbsolutePath -eq "/delete") {
                $inputStream = New-Object System.IO.StreamReader($Request.InputStream)
                $data = $inputStream.ReadToEnd()

                $responseTable = @{}
                $data -split "&" | ForEach-Object {
                    $key, $value = $_ -split "="
                    $value = [System.Web.HttpUtility]::UrlDecode($value)
                    $responseTable.Add($key, $value)
                }

                $posts = Get-Content -Path "data/notes.json" | ConvertFrom-Json
                $posts.posts = $posts.posts | Where-Object { $_.id -ne $responseTable.id }
                $posts | ConvertTo-Json -Compress | Set-Content -Path "data/notes.json"

                Write-Host "🗑  Post deleted: $($responseTable.title) ($($responseTable.id))"
                $responseString = '<div id="statusMessage" class="alert alert-success" role="alert"><strong>Post deleted!</strong> Check it out on the home page</div>'
            } else {
                $responseString = "<html><body><h1>404 Not Found</h1></body></html>"
                $Response.StatusCode = 404
            }
        }
        default {
            $responseString = "<html><body><h1>Method Not Supported</h1></body></html>"
            $Response.StatusCode = 405
        }
    }

    # Respond to the client
    $buffer = [System.Text.Encoding]::UTF8.GetBytes($responseString)
    $Response.ContentLength64 = $buffer.Length
    $Response.OutputStream.Write($buffer, 0, $buffer.Length)
    $Response.OutputStream.Close()
    
    # Break loop if killed
    if ($bKill) { break }
}

# Main loop
while ($true) {
    $context = $listener.GetContext()
    $request = $context.Request
    $response = $context.Response

    Write-Host "👀 Request received: $($request.HttpMethod) $($request.Url)"

    Handle-Request -Request $request -Response $response
}
