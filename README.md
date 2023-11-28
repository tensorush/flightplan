## :lizard: :small_airplane: **flightplan**

[![CI][ci-shield]][ci-url]
[![CD][cd-shield]][cd-url]
[![DC][dc-shield]][dc-url]
[![CC][cc-shield]][cc-url]
[![LC][lc-shield]][lc-url]

### [Flight plan](https://en.wikipedia.org/wiki/Flight_plan) parsing utilities based on the [libflightplan repo](https://github.com/mitchellh/libflightplan) created by [Mitchell Hashimoto](https://github.com/mitchellh).

### :warning: Warning

#### **When planning an actual flight, be extremely careful to verify the library output in your avionics or EFB!!!**

### :rocket: Usage

1. Add `flightplan` as a dependency in your `build.zig.zon`.

    <details>

    <summary><code>build.zig.zon</code> example</summary>

    ```zig
    .{
        .name = "<package_name>",
        .version = "<package_version>",
        .dependencies = .{
            .flightplan = .{
                .url = "https://github.com/tensorush/flightplan/archive/<version_tag_or_commit_hash>.tar.gz",
                .hash = "<dependency_package_hash>",
            },
        },
        .paths = .{""},
    }
    ```

    Set `<package_hash>` to `12200000000000000000000000000000000000000000000000000000000000000000`, and Zig will provide the correct found value in an error message.

    </details>

2. Add `flightplan` as a module in your `build.zig`.

    <details>

    <summary><code>build.zig</code> example</summary>

    ```zig
    const flightplan = b.dependency("flightplan", .{});
    exe.addModule("flightplan", flightplan.module("flightplan"));
    ```

    </details>

### :battery: Progress

> Legend: :green_circle: - tested, :yellow_circle: - untested, :red_circle: - unimplemented.

| Name                                                                                      | Extension |     Reader     |     Writer     |
|-------------------------------------------------------------------------------------------|:---------:|:--------------:|:--------------:|
| [ForeFlight & Garmin](https://www8.garmin.com/xmlschemas/FlightPlanv1.xsd)                |    FPL    | :green_circle: | :green_circle: |
| [X-Plane 11](https://developer.x-plane.com/article/flightplan-files-v11-fms-file-format/) |    FMS    |  :red_circle:  | :green_circle: |

### :teacher: Resources

- #### :tv: [Private Pilot Ground School Videos from MIT](https://www.youtube.com/playlist?list=PLUl4u3cNGP63cUdAG3v311Vl72ozOiK25)

<!-- MARKDOWN LINKS -->

[ci-shield]: https://img.shields.io/github/actions/workflow/status/tensorush/flightplan/ci.yaml?branch=main&style=for-the-badge&logo=github&label=CI&labelColor=black
[ci-url]: https://github.com/tensorush/flightplan/blob/main/.github/workflows/ci.yaml
[cd-shield]: https://img.shields.io/github/actions/workflow/status/tensorush/flightplan/cd.yaml?branch=main&style=for-the-badge&logo=github&label=CD&labelColor=black
[cd-url]: https://github.com/tensorush/flightplan/blob/main/.github/workflows/cd.yaml
[dc-shield]: https://img.shields.io/badge/click-F6A516?style=for-the-badge&logo=zig&logoColor=F6A516&label=docs&labelColor=black
[dc-url]: https://tensorush.github.io/flightplan
[cc-shield]: https://img.shields.io/codecov/c/github/tensorush/flightplan?style=for-the-badge&labelColor=black
[cc-url]: https://app.codecov.io/gh/tensorush/flightplan
[lc-shield]: https://img.shields.io/github/license/tensorush/flightplan.svg?style=for-the-badge&labelColor=black
[lc-url]: https://github.com/tensorush/flightplan/blob/main/LICENSE.md
