package com.example.demo;

import org.postgresql.util.PGobject;
import tools.jackson.core.JsonGenerator;
import tools.jackson.databind.SerializationContext;
import tools.jackson.databind.ValueSerializer;

/**
 * Serialize PostgreSQL json/jsonb columns as raw JSON — the way a production app
 * would configure it, and the way every other framework in this benchmark behaves.
 *
 * Without this, Jackson bean-serializes PGobject into
 * {"null":false,"type":"jsonb","value":"{\"key\":\"value\"}"} which inflates
 * response payloads and makes cross-framework results incomparable.
 *
 * Other PGobject types (e.g. interval via PGInterval) serialize as their
 * PostgreSQL text value instead of a bean-property object.
 *
 * Spring Boot 4 serves HTTP responses with Jackson 3 (tools.jackson), so this
 * is a Jackson 3 ValueSerializer registered via a JacksonModule bean in
 * {@link Application}.
 */
public class PGobjectSerializer extends ValueSerializer<PGobject> {

    @Override
    public void serialize(PGobject value, JsonGenerator gen, SerializationContext context) {
        String v = value.getValue();
        if (v == null) {
            gen.writeNull();
            return;
        }
        String type = value.getType();
        if ("json".equals(type) || "jsonb".equals(type)) {
            gen.writeRawValue(v);
        } else {
            gen.writeString(v);
        }
    }
}
