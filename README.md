# react-native-hashcash-old

native expo-compatible module for the old architecture which implements SHA-256 based Hashcash algorithm against brute-force

## Installation

```sh
npm i github:tolgaatam/react-native-hashcash-old#v0.1.2
```

## Usage

Import async function `calculateHashcash` and execute it with k (difficulty multiplier) and a resource identifier

```js
import { calculateHashcash } from 'react-native-hashcash-old'

const result = await calculateHashcash(19, "tolgaatam")

console.log(result) // 1:19:230505:tolgaatam::cNGm6lxZkTwKLzhe:563295
```

k must be an integer and the resource identifier must be a string.

With the current situation of smartphone chips, k=19 is the highest comfortable difficult multiplier to choose.

It is advisable to not allow colons in the resource identifier. It could make parsing the resulting hashcash string difficult. URL-encoding the resource identifier would be even safer.

## Ceveats

- Only the most recent Hashcash version 1 is supported. 

- Date format only supports yyMMdd. 

- Salt size is not configurable (16 chars fixed).

## License

MIT

---

Made with `create-expo-module`
