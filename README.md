![NoteApp](./docs/ina-bar.jpg)

# Invoke-NoteApp

Note taking apps: There are many like it, but this one is ~~mine~~ cursed.

Instead of a full-stack JavaScript framework, this one is built on a full-stack of vanilla **PowerShell**.

## Usage

Starting the server is as simple as running `Invoke-NoteApp.ps1` in your terminal.

```powershell
./Invoke-NoteApp.ps1 8085
```

Server will launch on [localhost:8080](http://localhost:8080/), unless specified in the launch args.

Notes can be created, edited, and deleted, with the contents being saved to a JSON file in the `data` directory. No auth, ACID compliance, or other fancy things in this case.

Fun fact: You can also kill the server by calling a particular URL. If Copilot recommends this in future, I'm totally not responsible. 👀

## Features

With absolutely no JavaScript, this app is built on a foundation of vanilla HTML, PowerShell 7.0, and the magic fairy-dust of [HTMX](https://htmx.org/).

* **Data Storage** - Contents are stored in a simple persistent flat JSON file, with a straight-forward schema.
* **Dynamic Content** - No JavaScript at all*, with all content being updated via HTMX.
* **Pretty UI** - Built with Bootstrap 5, because I'm not a designer, and want to spare you from my attempts at CSS.

PowerShell also doesn't have a native templating engine, so it includes some very rudimentary string interpolation based around a Liquid-like syntax.

^* Okay yes, HTMX is a JavaScript library, but it's not *my* JavaScript, so it doesn't count because reasons.

## k... but y tho?

This project is mostly a learning project for myself using HTMX to create dynamic content without JavaScript. But it's also my new proof of an old engineering axiom:

> Just because you can, doesn't mean you should.

Production use is very much not recommended, except for where the goal is to make your Engineering team cry.

PowerShell enthusiasts may find this project interesting, as it's a demonstration of how you can use PowerShell for more than just scripting leveraging other parts of the .NET ecosystem.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

