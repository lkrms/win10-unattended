# Updates

`.cab` and `.msu` update packages downloaded to this directory from the
[Microsoft Update Catalog] are installed if applicable via
`DISM /Add-Package /IgnoreCheck`.

Packages provided for each update via its [catalog][Microsoft Update Catalog]
entry should be placed in their own directory, which must not have
subdirectories with additional packages.

Suggested layout if copying target-specific top-level directories to removable
media (i.e. if `Windows 11 24H2` is excluded when deploying `Windows 10 22H2`):

```
├── Windows 10 22H2
│   ├── KB5011048 Microsoft .NET Framework 4.8.1
│   │   └── windows10.0-kb5011048-x86_74a24b713a0af00a9d437c06904e2f5237fd96c9.msu
│   ├── KB5057056 2025-04 Cumulative Update Preview for .NET Framework 3.5, 4.8 and 4.8.1
│   │   ├── windows10.0-kb5056577-x86-ndp48_c17361e720d31358858ada9e29584c4764b47f44.msu
│   │   └── windows10.0-kb5056578-x86-ndp481_b5fde2911934a7c694a734ec0bc9bc4b42255523.msu
│   └── KB5060533 2025-06 Dynamic Cumulative Update
│       └── windows10.0-kb5060533-x86_fdf52f3d15c0476facd5d633b0c169b38f90d493.cab
└── Windows 11 24H2
    ├── KB5054979 2025-04 Cumulative Update for .NET Framework 3.5 and 4.8.1
    │   └── windows11.0-kb5054979-x64-ndp481_8e2f730bc747de0f90aaee95d4862e4f88751c07.msu
    └── KB5063060 2025-06 Cumulative Update
        ├── windows11.0-kb5043080-x64_953449672073f8fb99badb4cc6d5d7849b9c83e8.msu
        └── windows11.0-kb5063060-x64_96be31e3e3e1cbc216229abb83e5be9da4e08496.msu
```

[Microsoft Update Catalog]: https://catalog.update.microsoft.com/
