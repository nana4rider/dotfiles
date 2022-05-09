const vscode = require('vscode');
const macros = new Map();

macros.set('List2Array', function () {
  return convSelection(
    skipBlankLine,
    lines => lines.map(line => "'" + line.replace(/(?=')/g, '\\') + "',"),
    addNewLine
  );
});

macros.set('Tsv2MdTable', function () {
  const tomd = ar => '|' + ar.join('|') + '|';

  return convSelection(
    lines => {
      let header = false;
      return lines.reduce((newLines, line) => {
        if (line.length) {
          const cols = line.split(/\t/);
          newLines.push(tomd(cols));
          if (!header) {
            newLines.push(tomd(Array(cols.length).fill(' :- ')));
            header = true;
          }
        }
        return newLines;
      }, []);
    },
    addNewLine
  );
});

macros.set('UniqueSort', function () {
  return convSelection(
    skipBlankLine,
    uniqueLines,
    lines => lines.sort()
  );
});

macros.set('Sql2SPHPString', function () {
  return convSelection(
    skipBlankLine,
    lines => {
      return lines.map((sql, index) => {
        let str = '';
        if (index === 0) {
          str += '$sql = ';
        } else {
          str += '     . ';
        }
        const fsql = sql.replace(/"/g, '\\"').trimEnd();
        str += `"${fsql} "`;
        if (index === lines.length - 1) {
          str += ';';
        }
        return str;
      });
    },
    addNewLine
  );
});

macros.set('AddSlash', function () {
  return convSelection(
    lines => lines.map(line => {
      if (line.match(/^\s*\w/)) line = '/' + line.trim();
      return line;
    })
  );
});

macros.set('Json2Tsv', function () {
  return convSelection(
    skipBlankLine,
    json2String('\t'),
    addNewLine
  );
});

macros.set('Json2Csv', function () {
  return convSelection(
    skipBlankLine,
    json2String(',', s => '"' + String(s).replace(/(?=")/g, '"') + '"'),
    addNewLine
  );
});

macros.set('List2SqlIn', function () {
  return convSelection(
    skipBlankLine,
    uniqueLines,
    lines => lines.map(line => "'" + line.replace(/(?=')/g, "'") + "'"),
    toSingleLine(',', ' IN(', ')')
  );
});

const skipBlankLine = lines => lines.filter(line => line.trim().length);

const uniqueLines = lines => Array.from(new Set(lines).values());

const addNewLine = lines => {
  lines.push('');
  return lines;
};

const toSingleLine = (separator = '', prefix = '', suffix = '') => {
  return lines => [prefix + lines.join(separator) + suffix];
};

const json2String = (separator, wrapper = s => s) => {
  return lines => {
    let header = false;
    return lines.reduce((newLines, line) => {
      try {
        const data = JSON.parse(line);
        if (!header) {
          newLines.push(Object.keys(data).map(wrapper).join(separator));
          header = true;
        }
        newLines.push(Object.values(data).map(wrapper).join(separator));
      } catch (e) {
        if (!header) {
          throw e;
        }
        newLines.push(`${e.message}: ${line}`);
      }
      return newLines;
    }, []);
  };
};

function convSelection(...converter) {
  const editor = vscode.window.activeTextEditor;
  if (!editor) {
    return 'Editor is not opening.';
  }
  const document = editor.document;
  const selection = editor.selection;
  let range;
  let text = document.getText(selection);

  if (text.length > 0) {
    range = selection;
  } else {
    range = new vscode.Range(0, 0, document.lineCount + 1, 0);
    text = document.getText();
  }

  editor.edit(editBuilder => {
    const nl = document.eol === 1 ? "\n" : "\r\n";
    const newLines = converter.reduce((result, f) => f(result, nl), text.split(nl));
    editBuilder.replace(range, newLines.join(nl));
  });
}

module.exports.macroCommands = (function () {
  let no = 1;
  const commands = {};
  for (const [name, func] of macros.entries()) {
    commands[name] = { no, func };
    no++;
  }
  return commands;
})();
