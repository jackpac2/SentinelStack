import { useEffect, useState } from "react";
import { apiClient, API_BASE_URL } from "../api/client";
import StatusCard from "../components/StatusCard";

function SystemStatus() {
  const [health, setHealth] = useState({
    loading: true,
    status: "",
    service: "",
    uptime: null,
    responseTime: null,
    error: ""
  });
  const [slowState, setSlowState] = useState({
    loading: false,
    message: "",
    delayMs: null,
    responseTime: null,
    error: ""
  });
  const [errorState, setErrorState] = useState({
    loading: false,
    message: "",
    status: null
  });

  useEffect(() => {
    let ignore = false;

    const loadHealth = async () => {
      try {
        const { data, elapsedMs } = await apiClient.getHealth();
        if (!ignore) {
          setHealth({
            loading: false,
            status: data.status,
            service: data.service,
            uptime: data.uptime,
            responseTime: elapsedMs,
            error: ""
          });
        }
      } catch (error) {
        if (!ignore) {
          setHealth({
            loading: false,
            status: "unavailable",
            service: "cloudstore-backend",
            uptime: null,
            responseTime: error.elapsedMs || null,
            error: error.message || "Health check failed."
          });
        }
      }
    };

    loadHealth();

    return () => {
      ignore = true;
    };
  }, []);

  const runSlowTest = async () => {
    setSlowState({
      loading: true,
      message: "",
      delayMs: null,
      responseTime: null,
      error: ""
    });

    try {
      const { data, elapsedMs } = await apiClient.testSlowEndpoint();
      setSlowState({
        loading: false,
        message: data.message,
        delayMs: data.delayMs,
        responseTime: elapsedMs,
        error: ""
      });
    } catch (error) {
      setSlowState({
        loading: false,
        message: "",
        delayMs: null,
        responseTime: error.elapsedMs || null,
        error: error.message || "Slow endpoint test failed."
      });
    }
  };

  const triggerError = async () => {
    setErrorState({ loading: true, message: "", status: null });

    try {
      await apiClient.triggerErrorEndpoint();
      setErrorState({
        loading: false,
        message: "The endpoint returned an unexpected success response.",
        status: 200
      });
    } catch (error) {
      setErrorState({
        loading: false,
        message: error.message || "Intentional error triggered.",
        status: error.status || 500
      });
    }
  };

  return (
    <section className="page-card">
      <div className="section-heading">
        <div>
          <p className="eyebrow">System Status</p>
          <h1>Observability test console</h1>
        </div>
      </div>

      <div className="status-grid">
        <StatusCard title="Backend Health" tone={health.error ? "warning" : "healthy"}>
          <strong>{health.loading ? "Checking..." : health.status}</strong>
          <span>{health.service || "cloudstore-backend"}</span>
          <small>API: {API_BASE_URL}</small>
        </StatusCard>

        <StatusCard title="Response Time">
          <strong>{health.responseTime === null ? "--" : `${health.responseTime} ms`}</strong>
          <span>Latest health check</span>
          <small>
            Uptime {health.uptime === null ? "--" : `${health.uptime.toFixed(1)} s`}
          </small>
        </StatusCard>

        <StatusCard title="Slow Endpoint">
          <strong>{slowState.responseTime === null ? "--" : `${slowState.responseTime} ms`}</strong>
          <span>{slowState.delayMs ? `Server delay ${slowState.delayMs} ms` : "No test run yet"}</span>
          <button type="button" disabled={slowState.loading} onClick={runSlowTest}>
            {slowState.loading ? "Testing..." : "Test Slow Endpoint"}
          </button>
        </StatusCard>

        <StatusCard title="Error Endpoint" tone={errorState.status ? "warning" : "neutral"}>
          <strong>{errorState.status || "--"}</strong>
          <span>{errorState.message || "Trigger a controlled backend error."}</span>
          <button type="button" disabled={errorState.loading} onClick={triggerError}>
            {errorState.loading ? "Triggering..." : "Trigger Error Endpoint"}
          </button>
        </StatusCard>
      </div>

      {health.error ? <p className="notice-banner">{health.error}</p> : null}
      {slowState.error ? <p className="notice-banner">{slowState.error}</p> : null}
    </section>
  );
}

export default SystemStatus;
