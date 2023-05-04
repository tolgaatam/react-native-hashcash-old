# react-native-hashcash

native module with the old arch for implementing SHA-256 based Hashcash algorithm against brute-force

## Installation

```sh
npm i https://github.com/tolgaatam/react-native-hashcash-old
```

## Usage

Import async function `calculateHashcash` and execute it with k (difficulty multiplier) and user identifier

```js
import { calculateHashcash } from 'react-native-hashcash-old';

// ...

const result = await calculateHashcash(19, "tolgaatam");
```

k must be an integer and the user identifier must be a string.

## License

MIT

---

Made with `npx create-expo-module`
