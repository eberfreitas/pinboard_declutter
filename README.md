# Pinboard Declutter

Highly optionated script to update and remove bookmarks from [Pinboard](https://pinboard.in/).

Right now it...

- Checks for different title and description and updates the entry with new data;
- Checks if the URL is a 404 and deletes it;
- Checks if the URL is unavailable and deletes it;
- Follows redirects and replaces the old entry with the new one (only 301 and 302 http statuses).

## Compiling

You will need Elixir(1.9)/Erlang to compile. Download the code and run:

```
λ  mix escript.build
```

## Running

After compiling you can run the escript with this command:

```
λ  pinboard_declutter --username johndoe --password s3cr3t
```

You can also use your token like this:

```
λ pinboard_declutter --token user:NNNNNN
```

You can get your token on your [settings page](https://pinboard.in/settings/password).

### Running on windows

If you happen to be using Windows you need to use the `escript.exe` app, like
this:

```
λ escript pinboard_declutter --token user:NNNNNN
```

Just make sure that `escript.exe` is on your PATH env var.
