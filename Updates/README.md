# Updates

`.cab` and `.msu` update packages downloaded to this directory from the
[Microsoft Update Catalog] are installed via `DISM /Add-Package`.

Cumulative updates without "Dynamic" or "Preview" in the title are preferred
where possible.

Package files should be provided in one directory per update, as listed in the
update catalog, after checking the relevant knowledge base article for guidance
related to dependencies and installation order.

`DISM /Add-Package` is called once per directory with at least one `.cab` or
`.msu` file, in case-insensitive directory order.

## Suggested structure on technician computer

> [!IMPORTANT]
>
> Only copy top-level directories to removable media for targets they apply to.
> In the hierarchy below, for example, updates for `Windows 11 24H2` must not be
> provided when deploying `Windows 10 22H2`, and vice versa.

```
├── Windows 10 22H2
│   ├── KB5011048 Microsoft .NET Framework 4.8.1
│   │   └── windows10.0-kb5011048-x86_74a24b713a0af00a9d437c06904e2f5237fd96c9.msu
│   ├── KB5031539 2023-10 Servicing Stack Update
│   │   └── ssu-19041.3562-x86_5757db67f982216ee2f5973f4b3cfddbcae916b7.msu
│   ├── KB5057056 2025-04 Cumulative Update Preview for .NET Framework 3.5, 4.8 and 4.8.1
│   │   ├── windows10.0-kb5056577-x86-ndp48_c17361e720d31358858ada9e29584c4764b47f44.msu
│   │   └── windows10.0-kb5056578-x86-ndp481_b5fde2911934a7c694a734ec0bc9bc4b42255523.msu
│   └── KB5060533 2025-06 Cumulative Update
│       └── windows10.0-kb5060533-x86_de4a47dde17d91023f93eb9a37c6c96faebf768c.msu
└── Windows 11 24H2
    ├── KB5043080 2024-09 Cumulative Update
    │   └── windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu
    ├── KB5054979 2025-04 Cumulative Update for .NET Framework 3.5 and 4.8.1
    │   └── windows11.0-kb5054979-x64-ndp481_8e2f730bc747de0f90aaee95d4862e4f88751c07.msu
    └── KB5063060 2025-06 Cumulative Update
        └── windows11.0-kb5063060-x64_96be31e3e3e1cbc216229abb83e5be9da4e08496.msu
```

[Microsoft Update Catalog]: https://catalog.update.microsoft.com/
