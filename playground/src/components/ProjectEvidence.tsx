import { useLocale } from "../i18n/LocaleProvider";

export const repository = "https://github.com/LING71671/MoonSTRtree";
export function ProjectEvidence() {
  const { copy: t, locale } = useLocale();
  return (
    <>
      <section className="evidence-section" id="evidence">
        <div className="section-heading">
          <h2>{t.differenceTitle}</h2>
          <p>{t.differenceDescription}</p>
        </div>
        <div className="table-scroll">
          <table className="capability-table">
            <caption className="sr-only">{t.tableCaption}</caption>
            <thead>
              <tr>
                <th scope="col">{t.capability}</th>
                {["MoonSTRtree", "Flatbush", "RBush"].map((name) => (
                  <th key={name} scope="col">
                    {name}
                  </th>
                ))}
              </tr>
            </thead>
            <tbody>
              {t.capabilities.map(([name, ...values]) => (
                <tr key={name}>
                  <th scope="row">{name}</th>
                  {values.map((value, i) => (
                    <td key={i}>{value}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="source-note">
          {t.capabilitySources}{" "}
          <a
            href={`${repository}/blob/main/src/api/pkg.generated.mbti`}
            target="_blank"
            rel="noreferrer"
          >
            {t.interfaces}
          </a>
          ,{" "}
          <a
            href="https://github.com/mourner/flatbush#readme"
            target="_blank"
            rel="noreferrer"
          >
            Flatbush
          </a>
          ,{" "}
          <a
            href="https://github.com/mourner/rbush#readme"
            target="_blank"
            rel="noreferrer"
          >
            RBush
          </a>
          . {t.dynamicAdvantage}
        </p>
      </section>
      <section className="method-section">
        <h2>{t.methodTitle}</h2>
        <div className="method-grid">
          <div>
            <h3>{t.coreTitle}</h3>
            <p>{t.coreDescription}</p>
            <a
              href={`${repository}/tree/main/src/bridge/browser`}
              target="_blank"
              rel="noreferrer"
            >
              {t.bridge}
            </a>
          </div>
          <div>
            <h3>{t.repeatTitle}</h3>
            <p>{t.repeatDescription}</p>
            <p>{t.exportDescription}</p>
          </div>
          <div>
            <h3>{t.limitTitle}</h3>
            <p>{t.limitDescription}</p>
            <a
              href={`${repository}/blob/main/docs/${locale}/VALIDATION.md`}
              target="_blank"
              rel="noreferrer"
            >
              {t.validation}
            </a>
          </div>
        </div>
      </section>
    </>
  );
}
