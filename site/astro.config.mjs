// @ts-check
import { defineConfig } from 'astro/config';
import starlight from '@astrojs/starlight';
import { pluginLineNumbers } from '@expressive-code/plugin-line-numbers';
import { pluginCollapsibleSections } from '@expressive-code/plugin-collapsible-sections';

const REPO = 'https://github.com/iblancasa/kiali-tracing-tutorial';

// https://astro.build/config
export default defineConfig({
	site: 'https://iblancasa.github.io',
	base: '/kiali-tracing-tutorial',
	integrations: [
		starlight({
			title: 'Kiali and distributed tracing',
			description:
				'Hands-on tutorial: observe and troubleshoot applications in an Istio service mesh with Kiali, Jaeger, Prometheus, Grafana and OpenTelemetry, on your laptop.',
			social: [{ icon: 'github', label: 'GitHub', href: REPO }],
			editLink: { baseUrl: `${REPO}/edit/main/site/` },
			lastUpdated: true,
			customCss: ['./src/styles/custom.css'],
			// Starlight ships Expressive Code. https://expressive-code.com/
			expressiveCode: {
				themes: ['dracula', 'github-light'],
				plugins: [pluginLineNumbers(), pluginCollapsibleSections()],
				defaultProps: {
					showLineNumbers: false,
					overridesByLang: { 'python,java,js,ts': { showLineNumbers: true } },
				},
				styleOverrides: { borderRadius: '0.5rem' },
			},
			sidebar: [
				{ label: 'Start here', slug: 'start' },
				{ label: 'Before the tutorial', slug: 'prepare' },
				{
					label: 'The tutorial',
					items: [
						{ label: '1. Infrastructure', slug: 'steps/01-infrastructure' },
						{ label: '2. Deploying workloads', slug: 'steps/02-deploying-workloads' },
						{ label: '3. Tracing is broken', slug: 'steps/03-tracing-is-broken' },
						{ label: '4. Auto-instrumentation', slug: 'steps/04-auto-instrumentation' },
						{ label: '5. Next steps', slug: 'steps/05-next-steps' },
					],
				},
				{
					label: 'Reference',
					items: [
						{ label: 'Commands', slug: 'reference/commands' },
						{ label: 'Troubleshooting', slug: 'reference/troubleshooting' },
					],
				},
			],
		}),
	],
});
