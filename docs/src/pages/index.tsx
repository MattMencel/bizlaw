import type {ReactNode} from 'react';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout title={siteConfig.title} description={siteConfig.tagline}>
      <main style={{padding: '4rem 1rem', maxWidth: '48rem', margin: '0 auto'}}>
        <h1>{siteConfig.title}</h1>
        <p>{siteConfig.tagline}</p>
        <p>
          The engine is being rebuilt and there is no running application to
          document yet.
        </p>
        <Link className="button button--primary" to="/docs/intro">
          Read where the design lives
        </Link>
      </main>
    </Layout>
  );
}
