import { useTheme } from "../hooks/useTheme";

// Un seul bouton qui fait défiler les trois états : plus compact qu'un groupe
// de trois dans un bandeau déjà chargé.
const LIBELLES = {
  system: { icone: "◐", texte: "Thème : système" },
  light: { icone: "☀", texte: "Thème : clair" },
  dark: { icone: "☾", texte: "Thème : sombre" },
};

export default function ThemeToggle() {
  const { preference, suivant } = useTheme();
  const { icone, texte } = LIBELLES[preference];

  return (
    <button type="button" className="theme-toggle" onClick={suivant} title={texte} aria-label={texte}>
      <span aria-hidden="true">{icone}</span>
    </button>
  );
}
