import * as bootstrap from 'react-bootstrap';
import PropTypes from 'prop-types';
import React from 'react';
const {Col, Container, Row} = bootstrap;

function Footer(props) {
	const {darkMode, repositoryUrl, siteRevision} = props;

	return (
		<footer className={`footer ${darkMode ? 'dark-mode' : ''}`}>
			<Container fluid>
				<Row>
					<Col xs={4}>
						<small>{'Tested with '}
							<a
								href="https://www.browserstack.com/"
								rel="noopener noreferrer"
								target="_blank"
							>
								<img
									alt="BrowserStack Logo"
									height="25"
									src="/images/BrowserStack.png"
								/>
							</a>
						</small>
					</Col>
					<Col className="text-center" xs={4}>
						<small>Cover image by{' '}
							<a href="https://commons.wikimedia.org/wiki/File:Bookshelf.jpg">
								Stewart Butterfield
							</a> (
							<a href="https://creativecommons.org/licenses/by/2.0/deed.en">
								CC-BY-2.0
							</a>)
						</small>
					</Col>
					<Col className="text-right" xs={4}>
						<div className="small">
							<a href="/admin-logs">
								Admin Logs
							</a>
						</div>
						<div className="small">
							<a href="/privacy">
								Privacy & Terms
							</a>
						</div>
					</Col>
				</Row>
				<Row>
					<Col className="text-center" xs={12}>
						<small>
							Alpha Software —{' '}
							<a href={`${repositoryUrl}tree/${siteRevision || 'master'}`}>
								{siteRevision || 'unknown revision'}
							</a> —&nbsp;
							<a href="https://tickets.metabrainz.org/projects/BB/issues/">
								Report a Bug
							</a>
						</small>
					</Col>
				</Row>
			</Container>
		</footer>
	);
}

Footer.displayName = 'Footer';
Footer.propTypes = {
	darkMode: PropTypes.bool.isRequired,
	repositoryUrl: PropTypes.string.isRequired,
	siteRevision: PropTypes.string.isRequired
};

export default Footer;
